# OpenClaw Multi-Agent Collaboration System（三省六部）

> 一个通用的 OpenClaw 多 Agent 协同工作系统。**三省六部**架构，让 AI Agent 像团队一样协作。

## 🎯 是什么

基于 OpenClaw 的多 Agent 协同工作框架。一个 **调度 Agent** 居中协调，**8 个专业 Agent** 各司其职，形成完整的"需求→拆解→审查→执行→质检→交付"流水线。

```
老板下发任务
  ↓
调度Agent: 理解需求 → 补齐信息 → 生成需求摘要
  ↓
┌────────── 三省六部 ──────────┐
│                               │
│  规划Agent → TASK.md           │
│       ↓                       │
│  审议Agent → 独立审查/封驳       │
│       ↓                       │
│  调度拍板 → 派发               │
│       ↓                       │
│  派发Agent → 路由到执行部门     │
│   ├─ 文案Agent (可带子Agent)    │
│   ├─ 代码Agent (可带子Agent)    │
│   └─ 设计Agent (可带子Agent)    │
│       ↓                       │
│  审查Agent → 独立质量验收        │
│       ↓                       │
│  汇总Agent → 整合交付包         │
│                               │
└───────────────────────────────┘
  ↓
调度Agent: 最终审查 → 交付老板
```

## 🏛️ 三省六部 Agent 角色

每个 Agent 有独立人格和专属技能，按需随时扩编。

| Agent | 名号 | 职责 | 适合模型 |
|-------|------|------|---------|
| `guihua` | 筹微 | 需求分析 → 拆解任务 → 生成 TASK.md | DeepSeek/GPT (推理型) |
| `shenyi` | 审微 | 独立审查 TASK.md → 准奏或封驳 | DeepSeek (批判型) |
| `paifa` | 驿使 | 路由子任务到执行部门 | 轻量模型 |
| `wenan` | 墨卿 | 网站文案/品牌故事/SEO/翻译 | GLM/GPT (文案型) |
| `daima` | 锋铸 | 前端开发/功能实现/性能优化 | Claude (代码型) |
| `sheji` | 绘象 | 视觉规范/UI/生图/素材 | Gemini (视觉型) |
| `shencha` | 镜衡 | 独立质量验收/对照标准评分 | 高精度评论模型 |
| `huizong` | 归藏 | 整合交付/生成交付报告 | 轻量模型 |

## 🚀 快速安装

```bash
# 1. 克隆
git clone https://github.com/ilxu7z/baocheng-pm.git
cd baocheng-pm

# 2. 安装（自动注册 Agent + 配置同步）
chmod +x install.sh && ./install.sh

# 3. 添加 Agent 的 API Key（首次需要）
openclaw agents add guihua
# 按提示输入 API Key，然后重新运行 install.sh 同步到所有 Agent

# 4. 启动 Dashboard
chmod +x start.sh && ./start.sh

# 5. 打开看板
open http://127.0.0.1:7891
```

## 📋 看板 Dashboard

启动后访问 `http://127.0.0.1:7891`，提供：

- **旨意看板** — 所有任务的实时状态（Kanban 列视图）
  - 自动发现 OpenClaw 运行时的活跃会话，同步到看板
  - 支持手动创建/叫停/恢复任务
- **官员总览** — 各 Agent Token 消耗和活跃度统计
- **模型配置** — 每个 Agent 独立切换 LLM 模型
- **奏折阁** — 已完成任务自动归档，可回溯

### Dashboard 页面

| 页面 | 功能 |
|------|------|
| `/` 看板 | 任务 Kanban 视图（Doing/Review/Blocked/Done） |
| `/officials` 官员 | 各 Agent 消耗统计和活跃度 |
| `/config` 配置 | 每个 Agent 的模型设置 |
| `/archive` 存档 | 已完成任务归档查询 |

## 🔧 工作流

### 什么时候走三省六部

调度 Agent 根据任务复杂度自动判断：

#### 🔴 走三省六部流程（复杂任务）

| 信号 | 示例 |
|------|------|
| 涉及多人协作/多环节 | "帮我做个产品官网" |
| 需要计划+拆解 | "写一份营销方案" |
| 需要独立审查 | "出一份竞品分析" |
| 有交付物需多方评审 | "帮出一套品牌VI方案" |
| 用户主动触发三省六部 | "下旨：产品画册设计" |

#### 🟢 直接回答，不走流程（简单任务）

| 情况 | 示例 |
|------|------|
| 问信息 | "XX产品的参数是什么" |
| 小改动 | "把这个按钮改成蓝色" |
| 讨论/决策 | "你觉得这个方案怎么样" |
| 查看状态 | "看看看板有没有异常" |

### 如何主动触发

说以下任意一句，调度 Agent 就会启动三省六部流程：

```
用三省六部制，帮我做个XX
下旨：XX
启动三省六部，帮我XX
```

看板上也有「👑 下旨」按钮，效果一样。

### 🔄 完整流程

```
你说: "下旨：帮我做冲调类产品官网"

调度Agent:
1. 追问缺失信息 → 生成需求摘要
2. spawn guihua(筹微) → 产出 TASK.md
3. spawn shenyi(审微) → 审查 → 准奏/封驳
4. 封驳则修改 → 重新审议
5. 准奏 → spawn paifa(驿使) → 路由到各部门
6. 并行 spawn wenan/daima/sheji → 各自带子Agent执行
7. spawn shencha(镜衡) → 独立质量审查
8. spawn huizong(归藏) → 整合交付包
9. 交付给你
```

**你的投入：给任务 → 关键决策点确认 → 收结果。中间不用管。**

## 🔄 换电脑 / 重装部署

```bash
git clone https://github.com/ilxu7z/baocheng-pm.git
cd baocheng-pm
./install.sh
./start.sh
```

所有 Agent 配置和注册信息通过 Git 同步，换机一键恢复。

## ⚔️ 扩编 Agent

当项目需要当前军团没有的角色时，一键创建：

```bash
# 用法: add-agent.sh <agent_id> <display_name> <role> <description>
chmod +x scripts/add-agent.sh
./scripts/add-agent.sh shuju "数枢" "数据分析师" "数据采集、清洗、报表生成"
```

脚本自动完成：
1. 生成 SOUL.md（智能推荐适合该角色的 LLM 模型）
2. 注册到 `registry.json`
3. 注册到 OpenClaw
4. 创建 workspace + 同步 API Key
5. 更新 `sync_agent_config.py` 让 Dashboard 可配置

然后 `git add -A && git commit && git push`，任何电脑 clone 后 `./install.sh` 即可同步。

## 🔌 模型路由配置

系统支持每个 Agent 独立配置 LLM 模型，通过 Dashboard 管理或直接编辑 `registry.json`：

```json
{
  "guihua": {
    "model": "deepseek/deepseek-v4-pro",
    "name": "筹微",
    "skills": ["分析", "规划"]
  },
  "wenan": {
    "model": "Pro/zai-org/GLM-5.1",
    "name": "墨卿",
    "skills": ["文案", "翻译"]
  }
}
```

推荐按角色匹配模型：
- **推理/分析型**（规划、审查）→ DeepSeek / GPT
- **文案型**（文案）→ GLM-5.1
- **代码型**（开发）→ Claude
- **视觉型**（设计/生图）→ Gemini

## 🧬 技术架构

```
OpenClaw Multi-Agent Runtime
       ↓ 自动发现(15s间隔)
sync_from_openclaw_runtime.py
       ↓
tasks_source.json (看板数据源)
       ↓
Dashboard (React + Vite + Python http.server)
       ↓
看板UI、官员统计、模型配置、归档
```

| 组件 | 技术栈 |
|------|--------|
| Agent 运行时 | OpenClaw Runtime |
| 数据同步 | Python（零外部依赖, 仅 stdlib） |
| Dashboard 后端 | Python `http.server`（零外部依赖） |
| Dashboard 前端 | React 18 + TypeScript + Vite |
| 数据存储 | JSON 文件 |

## 📄 致谢

本项目看板引擎和架构设计受 [edict (三省六部)](https://github.com/cft0808/edict) 启发，Agent 层和调度逻辑完全重写以适配 OpenClaw 多 Agent 协同场景。

## 📜 License

MIT
