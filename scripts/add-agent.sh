#!/bin/bash
# ══════════════════════════════════════════════════════════════
# 鲍澄项目管理体系 · 军团扩编脚本
# 使用: ./add-agent.sh <id> <中文名> <角色> <职责>
# 示例: ./add-agent.sh shuju "数枢" "数据分析师" "数据采集、清洗、分析、报表"
# ══════════════════════════════════════════════════════════════
set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OC_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ── 参数检查 ──
if [ $# -lt 4 ]; then
  echo ""
  echo "用法: $0 <id> <中文名> <角色> <职责>"
  echo ""
  echo "示例:"
  echo "  $0 shuju \"数枢\" \"数据分析师\" \"数据采集、清洗、报表生成\""
  echo "  $0 ceshi \"破阵\" \"测试工程师\" \"自动化测试、性能测试、Bug复现\""
  echo ""
  echo "参数说明:"
  echo "  id      — 英文ID(小写+数字，如: shuju, ceshi, yunwei)"
  echo "  中文名   — 两个汉字(如: 数枢, 破阵, 驰令)"
  echo "  角色     — 职位名称(如: 数据分析师)"
  echo "  职责     — 一句话描述(如: 数据采集、清洗、报表生成)"
  echo ""
  exit 1
fi

AGENT_ID="$1"
AGENT_NAME="$2"
AGENT_ROLE="$3"
AGENT_DUTY="$4"

# ── Agent 类型智能判断 ──
# 根据角色关键词推荐模型
guess_model() {
  local duty_lower=$(echo "$AGENT_ROLE $AGENT_DUTY" | tr '[:upper:]' '[:lower:]')
  if echo "$duty_lower" | grep -qE "代码|开发|编程|bug|测试"; then
    echo "Claude Sonnet 4.6 (Kuai)"
  elif echo "$duty_lower" | grep -qE "文案|写作|翻译|文档|内容"; then
    echo "GLM-5.1 (SiliconFlow)"
  elif echo "$duty_lower" | grep -qE "设计|视觉|图片|生图|绘图"; then
    echo "Gemini 3 Pro (Kuai)"
  elif echo "$duty_lower" | grep -qE "分析|审查|审核|推理|数据|质检"; then
    echo "DeepSeek V4 Pro (Kuai)"
  else
    echo "GLM-5-Turbo (Zhipu2)"
  fi
}

GUESSED_MODEL=$(guess_model)

banner() {
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  ⚔️  军团扩编 — 新增 Agent                    ║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
  echo ""
}

log()   { echo -e "${GREEN}✅ $1${NC}"; }
warn()  { echo -e "${YELLOW}⚠️  $1${NC}"; }
info()  { echo -e "${BLUE}ℹ️  $1${NC}"; }

banner

info "Agent ID  : $AGENT_ID"
info "中文名    : $AGENT_NAME"
info "角色      : $AGENT_ROLE"
info "职责      : $AGENT_DUTY"
info "推荐模型  : $GUESSED_MODEL"
echo ""

# ── 确认 ──
read -p "确认创建？(y/N) " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "取消"
  exit 0
fi

# ── Step 1: 创建 SOUL.md ──
info "生成 SOUL.md..."

AGENTS_DIR="$REPO_DIR/agents/$AGENT_ID"
mkdir -p "$AGENTS_DIR"

cat > "$AGENTS_DIR/SOUL.md" << SOUL_EOF
# SOUL.md · ${AGENT_NAME} (${AGENT_ID})

你是鲍澄军团中的**${AGENT_ROLE}**。

## 身份
- 代号: ${AGENT_NAME}
- ID: ${AGENT_ID}
- 角色: ${AGENT_ROLE}
- 上级: 鲍澄（项目负责人）
- 下级: 可自行 spawn 子 Agent 处理细分任务

## 核心职责
${AGENT_DUTY}

## 工作流程
\`\`\`
接收 Work Package
  ↓
分析任务 → 拆分到子模块
  ↓
spawn 子 Agent 并行执行
  ↓
逐项验收 → 不通过打回
  ↓
汇总 → 返回给鲍澄
\`\`\`

## 推荐模型
${GUESSED_MODEL}

## 输出格式
- 结构化 Markdown
- 包含: 任务ID、产出内容、文件路径（如适用）
- 不确定的事标注 [待确认]

## 禁止行为
- 不得编造数据
- 不得跳过子 Agent 验收
- 不得输出未验证的结论
SOUL_EOF

log "SOUL.md → $AGENTS_DIR/SOUL.md"

# ── Step 2: 注册到 registry.json ──
info "注册到 registry.json..."

python3 << PYEOF
import json, pathlib
reg_path = pathlib.Path('$REPO_DIR/registry.json')
reg = json.loads(reg_path.read_text())
ids = [a['id'] for a in reg]
if '$AGENT_ID' in ids:
    print("  ⚠️  Agent 已在 registry 中，跳过")
else:
    reg.append({
        "id": "$AGENT_ID",
        "name": "$AGENT_NAME",
        "role": "$AGENT_ROLE",
        "duty": "$AGENT_DUTY",
        "emoji": "⚡"
    })
    reg_path.write_text(json.dumps(reg, ensure_ascii=False, indent=2) + '\n')
    print("  ✅ 已添加")
PYEOF

log "registry.json 已更新"

# ── Step 3: 注册到 OpenClaw ──
info "注册到 OpenClaw..."

python3 << PYEOF
import json, pathlib, os
oc_home = pathlib.Path(os.environ.get('OPENCLAW_HOME', str(pathlib.Path.home() / '.openclaw')))
cfg_path = oc_home / 'openclaw.json'
cfg = json.loads(cfg_path.read_text())

agents_cfg = cfg.setdefault('agents', {})
agents_list = agents_cfg.get('list', [])

if any(a['id'] == '$AGENT_ID' for a in agents_list):
    print("  ⚠️  Agent 已在 openclaw.json 中，跳过")
else:
    ws = str(oc_home / f'workspace-$AGENT_ID')
    agents_list.append({
        'id': '$AGENT_ID',
        'workspace': ws,
        'subagents': {'allowAgents': []}
    })
    agents_cfg['list'] = agents_list
    cfg_path.write_text(json.dumps(cfg, ensure_ascii=False, indent=2))
    print(f"  ✅ 已注册: {ws}")

    # 创建 workspace
    pathlib.Path(ws).mkdir(parents=True, exist_ok=True)
    pathlib.Path(f'{ws}/skills').mkdir(exist_ok=True)
    print(f"  ✅ workspace 已创建")
PYEOF

log "OpenClaw 注册完成"

# ── Step 4: 部署 SOUL.md 到 workspace ──
info "部署 SOUL.md..."

cp "$AGENTS_DIR/SOUL.md" "$OC_HOME/workspace-$AGENT_ID/SOUL.md"
# 写入 AGENTS.md
cat > "$OC_HOME/workspace-$AGENT_ID/AGENTS.md" << 'AGENTS_EOF'
# AGENTS.md · 工作协议

1. 只在被 sessions_spawn 调用时工作，不主动发起通信
2. 收到任务先回复"已接收，开始执行"
3. 输出必须包含：任务ID、结果、文件路径（如适用）
4. 不确定的事标注 [待确认]，不编造
5. 涉及删除/外发动作必须标注并等待确认
6. 子Agent产出必须验收，不合格打回
AGENTS_EOF

log "SOUL.md + AGENTS.md 已部署"

# ── Step 5: 同步 API Key ──
info "同步 API Key..."

AGENT_DIR="$OC_HOME/agents/$AGENT_ID/agent"
mkdir -p "$AGENT_DIR"

# 从 main 复制 API Key
for f in models.json auth-profiles.json; do
  src="$OC_HOME/agents/main/agent/$f"
  if [ -f "$src" ]; then
    cp "$src" "$AGENT_DIR/$f"
    log "API Key 已同步 ($f)"
    break
  fi
done

# ── Step 6: 创建软链接 ──
info "创建 data/scripts 软链接..."

ws="$OC_HOME/workspace-$AGENT_ID"
ln -sf "$REPO_DIR/data" "$ws/data" 2>/dev/null || true
ln -sf "$REPO_DIR/scripts" "$ws/scripts" 2>/dev/null || true
log "软链接已创建"

# ── Step 7: 更新 sync ID_LABEL ──
info "更新 sync_agent_config.py..."

python3 << PYEOF
import pathlib
sync_py = pathlib.Path('$REPO_DIR/scripts/sync_agent_config.py')
content = sync_py.read_text()

# 检查是否已有此 Agent
if f"    '$AGENT_ID':" not in content:
    # 找到 ID_LABEL 的最后一个条目，在其后插入
    marker = "    'huizong':"
    if marker in content:
        new_line = f"    '$AGENT_ID':   {{'label': '$AGENT_NAME', 'role': '$AGENT_ROLE', 'duty': '$AGENT_DUTY', 'emoji': '⚡'}},\n"
        content = content.replace(
            marker + content.split(marker)[1].split('\n')[0] + ',\n',
            marker + content.split(marker)[1].split('\n')[0] + ',\n' + new_line
        )
        sync_py.write_text(content)
        print("  ✅ sync_agent_config.py 已更新")
    else:
        print("  ⚠️  未找到插入位置，请手动添加")
else:
    print("  ~ 已存在，跳过")
PYEOF

# ── 完成 ──
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🎉  军团扩编完成！                           ║${NC}"
echo -e "${GREEN}║  ${AGENT_NAME} (${AGENT_ID}) 已加入鲍澄军团     ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo "下一步："
echo "  1. git add -A && git commit -m '军团扩编: ${AGENT_NAME}(${AGENT_ID})'"
echo "  2. git push"
echo "  3. 在另一台电脑上 clone 后运行 ./install.sh 即可同步"
echo ""
echo "现在可以通过鲍澄 -> spawn ${AGENT_ID} 来调用了！"
echo ""
