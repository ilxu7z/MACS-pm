#!/bin/bash
# ══════════════════════════════════════════════════════════════
# 鲍澄项目管理体系 · 一键启动
# 同时启动看板服务器 + 数据刷新循环
# ══════════════════════════════════════════════════════════════

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# ── 找到 Python 3.10+ ──
resolve_python() {
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    command -v "$candidate" &>/dev/null || continue
    version=$("$candidate" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null) || continue
    major=${version%%.*}
    minor=${version#*.}
    if [ "$major" -gt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -ge 10 ]; }; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON_BIN=$(resolve_python) || {
  echo -e "${RED}❌ 未找到 Python 3.10+${NC}"
  exit 1
}

# ── 确保 data 目录存在 ──
mkdir -p "$REPO_DIR/data"
for f in live_status.json agent_config.json model_change_log.json sync_status.json; do
  [ ! -f "$REPO_DIR/data/$f" ] && echo '{}' > "$REPO_DIR/data/$f"
done
[ ! -f "$REPO_DIR/data/pending_model_changes.json" ] && echo '[]' > "$REPO_DIR/data/pending_model_changes.json"
[ ! -f "$REPO_DIR/data/tasks_source.json" ] && echo '[]' > "$REPO_DIR/data/tasks_source.json"
[ ! -f "$REPO_DIR/data/tasks.json" ] && echo '[]' > "$REPO_DIR/data/tasks.json"

# ── 优雅退出 ──
cleanup() {
  echo ""
  echo -e "${YELLOW}正在关闭服务...${NC}"
  kill $SERVER_PID $LOOP_PID 2>/dev/null
  wait $SERVER_PID $LOOP_PID 2>/dev/null
  echo -e "${GREEN}✅ 已关闭${NC}"
  exit 0
}
trap cleanup SIGINT SIGTERM

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🏛️  鲍澄项目管理体系 · 启动中           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo ""

# 启动数据刷新循环（后台）
echo -e "${GREEN}▶ 启动数据刷新循环...${NC}"
export EDICT_HOME="$REPO_DIR"
export EDICT_PYTHON="$PYTHON_BIN"
bash scripts/run_loop.sh &
LOOP_PID=$!

# 启动看板服务器
echo -e "${GREEN}▶ 启动看板服务器 (port 7891)...${NC}"
"$PYTHON_BIN" dashboard/server.py &
SERVER_PID=$!

sleep 1
echo ""
echo -e "${GREEN}✅ 服务已启动！${NC}"
echo -e "   看板地址: ${BLUE}http://127.0.0.1:7891${NC}"
echo -e "   按 ${YELLOW}Ctrl+C${NC} 关闭所有服务"
echo ""

# 尝试打开浏览器
if command -v open &>/dev/null; then
  open http://127.0.0.1:7891
fi

wait $SERVER_PID $LOOP_PID 2>/dev/null
