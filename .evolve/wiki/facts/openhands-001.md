---
domain: open-source-agent-framework
project: OpenHands
conclusion: OpenHands 是当前 GitHub star 数最高的开源 AI Agent 框架之一，产品形态覆盖 SDK / CLI / GUI / Cloud / Enterprise 五层，核心架构以 EventStream 事件驱动为 backbone，Runtime-Sandbox 隔离执行环境，Agent-Controller-State 三元组驱动主循环。1.0.0（2025-12-16）引入 software-agent-sdk 完成重大架构重构。
evidence_type: [url, raw, local-command]
timestamp: 2026-04-28
expires: 2026-07-28
confidence: high
independent_sources: 3
---

# OpenHands — 项目事实卡

## 1. 项目概览

| 字段 | 值 | 来源 |
|------|-----|------|
| 原名 | OpenDevin | 社区历史 [ref: raw:openhands-repo-api.json] |
| 现名 | OpenHands | GitHub org: OpenHands [ref: raw:openhands-repo-api.json] |
| 定位 | AI-Driven Development / Automated AI Software Engineer | GitHub description [ref: raw:openhands-repo-api.json] |
| 主语言 | Python（6.08 MB），TypeScript（3.54 MB） | GitHub languages API [ref: raw:openhands-languages.json] |
| License | MIT（核心代码），enterprise/ 目录 source-available | README [ref: raw:openhands-readme.md] |
| Stars | 72,234 | GitHub repo API [ref: raw:openhands-repo-api.json] |
| Forks | 9,122 | GitHub repo API [ref: raw:openhands-repo-api.json] |
| Open Issues | 413 | GitHub repo API [ref: raw:openhands-repo-api.json] |
| 创建时间 | 2024-03-13 | GitHub repo API [ref: raw:openhands-repo-api.json] |
| 官网 | https://openhands.dev | repo homepage [ref: raw:openhands-repo-api.json] |
| 主分支 | main | GitHub repo API [ref: raw:openhands-repo-api.json] |

## 2. 版本与发布节奏

| 版本 | 日期 | 关键变化 |
|------|------|----------|
| 0.62.0 | 2025-11-11 | 末版 0.x |
| 1.0.0 | 2025-12-16 | **重大重构**：引入 software-agent-sdk；CLI 拆分到独立仓库 OpenHands-CLI；Task Tracker 界面 [ref: raw:openhands-releases-api.json] |
| 1.1.0 | 2025-12-30 | OAuth 2.0 Device Flow、Forgejo 集成、tini 替换 micromamba [ref: raw:openhands-releases-api.json] |
| 1.2.0 | 2026-01-15 | 状态指示器、condenser max_size 120→240 [ref: raw:openhands-releases-api.json] |
| 1.3.0 | 2026-02-02 | CORS 支持、host networking mode [ref: raw:openhands-releases-api.json] |
| 1.4.0 | 2026-02-17 | MiniMax-M2.5 模型支持 [ref: raw:openhands-releases-api.json] |
| 1.5.0 | 2026-03-11 | Planning Agent、Bitbucket Datacenter、Task List 实时面板、多模型支持（Claude Opus 4.6 等）[ref: raw:openhands-releases-api.json] |
| 1.6.0 | 2026-03-30 | Hooks 支持、/clear 命令、代码块复制按钮、CVE 修复 [ref: raw:openhands-releases-api.json] |

**发布节奏**：约每 2-4 周一个小版本，1.0.0 后保持活跃迭代。

## 3. 产品形态矩阵

OpenHands 采用「五层产品矩阵」，覆盖从开发者到企业的全场景：

| 层级 | 形态 | 技术栈 | 说明 |
|------|------|--------|------|
| L1 SDK | software-agent-sdk（独立仓库） | Python | 可组合式 Agent 库，支持本地到云端千级 Agent 扩展 [ref: raw:openhands-readme.md] |
| L2 CLI | OpenHands-CLI（已拆分） | Python | 类 Claude Code / Codex 的终端交互体验 [ref: raw:openhands-readme.md] |
| L3 GUI | Local GUI（本仓库） | React + FastAPI | 单页应用，类 Devin / Jules 体验 [ref: raw:openhands-readme.md] |
| L4 Cloud | app.all-hands.dev | SaaS | 免费试用（Minimax 模型），含 Slack/Jira/Linear 集成 [ref: raw:openhands-readme.md] |
| L5 Enterprise | 自托管 Kubernetes | Source-available | VPC 内部署，RBAC、协作、扩展支持 [ref: raw:openhands-readme.md] |

**架构决策**：1.0.0 将 CLI 拆分为独立仓库，SDK 独立为 software-agent-sdk（678 stars），主仓库聚焦 GUI + Server + Cloud。

## 4. 核心架构

### 4.1 关键类与职责

基于 `openhands/README.md` 和源码结构 [ref: raw:openhands-core-contents.json]：

| 类/模块 | 职责 |
|---------|------|
| LLM | 通过 LiteLLM 统一代理所有大模型交互，支持任意 completion 模型 |
| Agent | 观察当前 State，产出推动目标前进的 Action |
| AgentController | 初始化 Agent、管理 State、驱动主循环逐步推进 |
| State | 表示 Agent 任务的当前状态：当前步数、事件历史、长期计划等 |
| EventStream | 事件中心枢纽：任意组件可发布/监听事件，是系统通信 backbone |
| Event | Action（请求，如编辑文件、执行命令）或 Observation（环境反馈） |
| Runtime | 执行 Action，返回 Observation；Sandbox 负责在 Docker 等环境中运行命令 |
| Server | HTTP 会话代理，驱动前端 |
| Session | 持有单个 EventStream + AgentController + Runtime，代表单个任务 |
| ConversationManager | 维护活跃会话列表，路由请求到正确 Session |

### 4.2 控制流伪代码

```python
while True:
    prompt = agent.generate_prompt(state)
    response = llm.completion(prompt)
    action = agent.parse_response(response)
    observation = runtime.run(action)
    state = state.update(action, observation)
```

实际实现通过 EventStream 消息传递完成 [ref: raw:openhands-core-readme.md]：

```
Agent --Actions--> AgentController --Actions--> EventStream
EventStream --Observations--> AgentController --State--> Agent
EventStream --Actions--> Runtime --Observations--> EventStream
Frontend --Actions--> EventStream
```

### 4.3 目录结构

```
openhands/                 # Python 后端
  app_server/              # V1 应用服务器（FastAPI）
    app_conversation/      # 会话管理
    app_lifespan/          # 生命周期
    config_api/            # 配置 API
    event/                 # 事件路由
    git/                   # Git 集成
    mcp/                   # MCP 协议支持
    sandbox/               # 沙箱管理
    services/              # 业务服务
    settings/              # 设置
    user/                  # 用户
    web_client/            # Web 客户端
  core/                    # 核心组件
    config/                # 配置系统
    const/                 # 常量
    schema/                # 数据 schema
  integrations/            # 第三方集成
  server/                  # 服务端（兼容层）
    config/
    services/
    user_auth/
  storage/                 # 存储层
  utils/                   # 工具
frontend/                  # React 前端
enterprise/                # 企业版（source-available）
containers/                # Docker 容器定义
skills/                    # Agent 技能定义
.agents/                   # Agent 配置
```

## 5. 关键技术栈

| 组件 | 技术选择 | 说明 |
|------|----------|------|
| LLM 代理 | LiteLLM (>=1.74.3) | 统一多模型接口，避免 vendor lock-in |
| Web 框架 | FastAPI + uvicorn | 后端 API 层 |
| 前端 | React + TanStack Query | 单页应用，数据获取标准化 |
| Sandbox | Docker + tmux + Playwright | 命令执行 + 浏览器自动化 |
| 浏览器自动化 | browsergym-core (0.13.3) | 网页浏览与操作 |
| 构建 | Poetry / uv 双锁文件 | 兼容两种包管理器 |
| Python 版本 | >=3.12, <3.14 | 较新的 Python 要求 |
| 自研组件 | openhands-sdk, openhands-tools, openhands-agent-server (==1.17) | 1.0 后提取的共享组件 |
| 可观测性 | OpenTelemetry | API >=1.33.1 |
| 实时通信 | python-socketio (5.14) | WebSocket 事件推送 |

## 6. 差异化特征

1. **EventStream 事件驱动架构**：所有组件通过统一事件总线通信，Agent、Runtime、Frontend 松耦合 [ref: raw:openhands-core-readme.md]
2. **五层产品矩阵**：构建了从 SDK 到 Enterprise 的完整产品矩阵，覆盖开发者工具、SaaS 托管和企业私有化部署三层商业形态 [ref: raw:openhands-readme.md]
3. **Runtime 可插拔**：支持 Docker Sandbox 和本地运行（`RUNTIME=local`），Dev/Prod 一致 [ref: raw:openhands-agents.md]
4. **多模型原生支持**：通过 LiteLLM 支持 Claude、GPT、Gemini、Qwen、Kimi、GLM 等主流模型 [ref: raw:openhands-releases-api.json]
5. **软件工程实践**：pre-commit、pytest、vitest、Mypy、Ruff 完整工具链；`.pr/` 目录机制管理临时产物 [ref: raw:openhands-agents.md]

## 7. 已知限制与风险

- **License 混合**：核心 MIT，但 enterprise/ 目录 source-available，商业使用需注意边界
- **Python 版本要求较新**：>=3.12 限制了一些旧环境部署
- **CLI 已拆分**：1.0.0 后 CLI 不在主仓库，需单独安装 OpenHands-CLI
- **Issue 数量**：413 open issues，维护负担较大
- **依赖复杂**：超过 60 个核心依赖，含多个自研组件（openhands-sdk/tools/agent-server）

## Sources

- raw:.evolve/raw/openhands-repo-api.json — GitHub repo metadata (API: https://api.github.com/repos/OpenHands/OpenHands)
- raw:.evolve/raw/openhands-releases-api.json — GitHub releases (API: https://api.github.com/repos/OpenHands/OpenHands/releases)
- raw:.evolve/raw/openhands-contents-api.json — Root directory structure (API: /contents)
- raw:.evolve/raw/openhands-core-contents.json — Core module structure (API: /contents/openhands)
- raw:.evolve/raw/openhands-languages.json — Language statistics (API: /languages)
- raw:.evolve/raw/openhands-agents.md — Repository contributor guide (https://raw.githubusercontent.com/OpenHands/OpenHands/main/AGENTS.md)
- raw:.evolve/raw/openhands-readme.md — Project README (https://raw.githubusercontent.com/OpenHands/OpenHands/main/README.md)
- raw:.evolve/raw/openhands-core-readme.md — Core module README (https://raw.githubusercontent.com/OpenHands/OpenHands/main/openhands/README.md)
- raw:.evolve/raw/openhands-pyproject.toml — Dependency and build config (https://raw.githubusercontent.com/OpenHands/OpenHands/main/pyproject.toml)
- url:https://github.com/OpenHands/software-agent-sdk — SDK 独立仓库
