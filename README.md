# 鲍澄项目管理体系

## 🎯 是什么

基于 OpenClaw 的多 Agent 协同工作系统。

**鲍澄**（你信任的项目负责人）居中调度，**8 个专业 Agent** 各司其职：

```
老板下发任务
  ↓
鲍澄: 理解需求 → 补齐信息 → 生成需求摘要
  ↓
┌────────── 协同层 ──────────┐
│                              │
│  规划Agent → TASK.md          │
│       ↓                      │
│  审议Agent → 独立审查/封驳      │
│       ↓                      │
│  鲍澄拍板 → 派发               │
│       ↓                      │
│  派发Agent → 路由到执行部门     │
│   ├─ 文案Agent (可带子Agent)   │
│   ├─ 代码Agent (可带子Agent)   │
│   └─ 设计Agent (可带子Agent)   │
│       ↓                      │
│  审查Agent → 独立质量验收       │
│       ↓                      │
│  汇总Agent → 整合交付包        │
│                              │
└──────────────────────────────┘
  ↓
鲍澄: 最终审查 → 交付老板
```

## 🏛️ Agent 角色

| Agent | 角色 | 职责 |
|-------|------|------|
| `guihua` | 筹微 | 需求分析 → 拆解任务 → 生成 TASK.md |
| `shenyi` | 审微 | 独立审查 TASK.md → 准奏或封驳 |
| `paifa` | 驿使 | 路由子任务到执行部门 |
| `wenan` | 墨卿 | 网站文案/品牌故事/SEO/翻译 |
| `daima` | 锋铸 | 前端开发/功能实现/性能优化 |
| `sheji` | 绘象 | 视觉规范/UI/生图/素材 |
| `shencha` | 镜衡 | 独立质量验收/对照标准评分 |
| `huizong` | 归藏 | 整合交付/生成交付报告 |

## 🚀 安装

```bash
# 1. 克隆
git clone https://github.com/ilxu7z/baocheng-pm.git
cd baocheng-pm

# 2. 安装
chmod +x install.sh && ./install.sh

# 3. 配置 API Key（首次）
openclaw agents add guihua
# 按提示输入 API Key，然后重新运行 install.sh 同步到所有 Agent

# 4. 启动
chmod +x start.sh && ./start.sh

# 5. 打开看板
open http://127.0.0.1:7891
```

## 📋 看板

启动后访问 `http://127.0.0.1:7891`，可以看到：

- **旨意看板** — 所有任务的实时状态（Kanban 列视图）
- **官员总览** — 各 Agent Token 消耗和活跃度
- **模型配置** — 每个 Agent 独立切换 LLM
- **奏折阁** — 已完成任务自动归档

## 🔧 工作流

和鲍澄对话即可，流程自动触发：

```
你说: "帮我做冲调类产品官网"

鲍澄:
1. 追问缺失信息 → 生成需求摘要
2. spawn guihua → 产出 TASK.md
3. spawn shenyi → 审查 → 准奏/封驳
4. 封驳则修改 → 重新审议
5. 准奏 → spawn paifa → 路由到各部门
6. 并行 spawn wenan/daima/sheji → 各自带子Agent执行
7. spawn shencha → 独立质量审查
8. spawn huizong → 整合交付包
9. 交付给你
```

**你的投入：给任务 → 关键决策点确认 → 收结果。中间不用管。**

## 🔄 换电脑/重装

```bash
git clone https://github.com/ilxu7z/baocheng-pm.git
cd baocheng-pm
./install.sh
./start.sh
```

## ⚔️ 扩编 — 按需创建新 Agent

当项目需要当前军团没有的角色时：

```bash
# 一键创建
chmod +x scripts/add-agent.sh
./scripts/add-agent.sh shuju "数枢" "数据分析师" "数据采集、清洗、报表生成"
```

脚本自动完成：
1. 生成 SOUL.md（智能推荐模型）
2. 注册到 registry.json
3. 注册到 OpenClaw
4. 创建 workspace + 同步 API Key
5. 更新 sync_agent_config.py

然后 `git add -A && git commit && git push`，任何电脑 clone 后 `./install.sh` 即可同步。

## 🧬 技术架构

- OpenClaw 多 Agent 系统
- React 18 + TypeScript + Vite（看板前端）
- Python stdlib http.server（看板后端，零依赖）
- 数据驱动：JSON 文件 + 15s 自动同步

## 📄 致谢

本项目看板引擎和数据结构基于 [edict (三省六部)](https://github.com/cft0808/edict)，Agent 层完全重写以适配「鲍澄居中调度」的架构理念。
