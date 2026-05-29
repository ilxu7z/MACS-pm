"""Session Checker — 轮询 OpenClaw 会话，检测用户验收信号。

Plan A: Dashboard 主动轮询 Session，发现用户已在对话中验收则自动推进任务状态。
解决痛点：用户在 Chat 里说"可以了"之后，不需要再跑到看板手动点「准奏」。
"""

import asyncio
import json
import logging
import re
import subprocess
from datetime import datetime, timezone, timedelta
from typing import Optional

log = logging.getLogger("edict.session_checker")

# ── 用户验收信号匹配 ──
# 中文
APPROVAL_PATTERNS = [
    # 单句通过
    re.compile(r'^\s*(可以了?|可以|通过|过了|没问题|OK|ok|好的|okay|就这样|好了|批准|同意|行|对|对的|嗯|好|好[的的]?)\s*[!！。.]?\s*$'),
    # 短语通过
    re.compile(r'(看起来?\s*(不错|很好|没问题|OK|ok|可以))'),
    re.compile(r'(就\s*(这样|照这样|按这|照这|按这个|照这个|按这样))'),
    re.compile(r'(照\s*(这样|这个|这么做|这样做))'),
    re.compile(r'(通过了?|验收通过|审查通过|审核通过)'),
    re.compile(r'(没有?问题|没啥问题|没什么问题)'),
    # 英文
    re.compile(r'(looks?\s*(good|great|fine|ok|awesome|perfect))', re.IGNORECASE),
    re.compile(r'(LGTM|lgtm|ship\s*it|approved|approve)', re.IGNORECASE),
]

# 否决信号 — 明确说"不行"（不应自动推进）
REJECT_PATTERNS = [
    re.compile(r'(不行|不对|不好|重做|重来|改一下|再改|修一下|修复|有问题|不对的)'),
    re.compile(r'(redo|rewrite|fix|wrong|incorrect|change)', re.IGNORECASE),
]

# 转折词 — 出现在通过信号之后表示有条件，不应自动推进
# 例: "可以，但是颜色要改" → 不自动验收
CONTRADICTION_PATTERNS = [
    re.compile(r'(但是|不过|但[^心]|然而|只是|除了|可是|就是|需要改|还要改|还得改|再调)'),
    re.compile(r'(but|however|except|although|though|need.*(change|fix|update|adjust))', re.IGNORECASE),
]


async def check_session_approval(
    agent_id: str,
    task_id: str = "",
    min_wait_seconds: int = 60,
    max_age_minutes: int = 30,
    openclaw_bin: str = "openclaw",
) -> tuple[bool, Optional[str]]:
    """检查指定 Agent 的最近会话中用户是否已验收。

    Returns:
        (approved: bool, reason: str | None)
        - (True, "用户说'可以了'") — 检测到验收
        - (False, None) — 未检测到
        - (False, "no_recent_sessions") — 无最近会话
        - (False, "user_rejected") — 用户说了不行
        - (False, "too_early") — 太早，等等再看
    """
    try:
        result = await asyncio.to_thread(
            lambda: subprocess.run(
                [openclaw_bin, "sessions", "list", "--json", "--agent", agent_id, "--active", str(max_age_minutes)],
                capture_output=True, text=True, timeout=15,
            )
        )

        if result.returncode != 0:
            err = result.stderr[:200] if result.stderr else "unknown error"
            log.debug(f"Session list failed for agent {agent_id}: {err}")
            return False, None

        sessions_raw = result.stdout.strip()
        if not sessions_raw:
            return False, "no_recent_sessions"

        sessions = json.loads(sessions_raw)
        if not sessions:
            return False, "no_recent_sessions"

    except subprocess.TimeoutExpired:
        log.warning(f"Session check timeout for agent {agent_id}")
        return False, None
    except json.JSONDecodeError as e:
        log.warning(f"Failed to parse session JSON for agent {agent_id}: {e}")
        return False, None
    except Exception as e:
        log.error(f"Session check error for agent {agent_id}: {e}")
        return False, None

    now = datetime.now(timezone.utc)
    min_time = now - timedelta(seconds=min_wait_seconds)

    for session in sessions:
        # 兼容多种 JSON 格式
        last_msg = (session.get("lastMessage")
                    or session.get("last_message")
                    or {})

        role = last_msg.get("role", "")
        content = (last_msg.get("content", "")
                   or last_msg.get("text", "")
                   or "")

        ts_str = (last_msg.get("timestamp")
                  or last_msg.get("at")
                  or session.get("updatedAt", "")
                  or session.get("updated_at", ""))

        if role != "user":
            continue

        # 时间检查：消息不能太新（用户可能还在审）
        try:
            ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
            if ts > min_time:
                return False, "too_early"
        except (ValueError, TypeError):
            pass  # 时间无法解析则忽略时间约束

        content_stripped = content.strip()

        # 先检查否决
        for pattern in REJECT_PATTERNS:
            if pattern.search(content_stripped):
                log.info(f"🚫 User rejection detected for agent {agent_id}: '{content_stripped[:80]}'")
                return False, "user_rejected"

        # 检查通过
        for pattern in APPROVAL_PATTERNS:
            if pattern.search(content_stripped):
                # 额外检查：是否有转折/条件（"可以，但是..."）
                has_contradiction = any(
                    cp.search(content_stripped) for cp in CONTRADICTION_PATTERNS
                )
                if has_contradiction:
                    log.info(f"⚠️ Approval pattern found but with contradiction for agent {agent_id}: '{content_stripped[:80]}'")
                    return False, "user_conditional"
                log.info(f"✅ Detected user approval for agent {agent_id} (task {task_id}): '{content_stripped[:80]}'")
                return True, f"用户在会话中说'{content_stripped[:40]}'"

    return False, None
