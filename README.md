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

### 🎯 什么时候触发三省六部

鲍澄根据任务复杂度自动判断。规则如下：

#### 🔴 走三省六部流程（复杂任务）

| 信号 | 示例 |
|------|------|
| 涉及多人协作/多环节 | "帮我做个冲调类产品官网" |
| 需要计划+拆解 | "写一份营销活动方案" |
| 需要独立审查 | "出一份竞品分析报告" |
| 有交付物需多方评审 | "帮出一套品牌VI方案" |
| 你主动说了下旨/启动 | "下旨：产品画册设计" |

#### 🟢 直接回答，不走流程（简单任务）

| 情况 | 示例 |
|------|------|
| 问信息 | "XX产品的参数是什么" |
| 小改动 | "把这个按钮改成蓝色" |
| 讨论/决策 | "你觉得这个方案怎么样" |
| 查看状态 | "看看看板有没有异常" |

### 📜 如何主动触发

说以下任意一句，鲍澄就会启动三省六部流程：

```
用三省六部制，帮我做个XX
下旨：XX
启动三省六部，帮我XX
```

### 🔄 完整流程

```
你说: "下旨：帮我做冲调类产品官网"

鲍澄:
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

**也可以在看板上直接点「👑 下旨」按钮创建任务，效果一样。**

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
