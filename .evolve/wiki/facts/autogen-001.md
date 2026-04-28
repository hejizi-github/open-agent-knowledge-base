---
domain: open-source-agent-framework
conclusion: AutoGen Project Fact Sheet
evidence_sources:
  - "raw:.evolve/raw/autogen-repo-api.json — GitHub repo metadata API response"
  - "raw:.evolve/raw/autogen-release-api.json — GitHub releases API (10 latest)"
  - "raw:.evolve/raw/autogen-readme.md — decoded README from GitHub contents API"
  - "raw:.evolve/raw/autogen-core-readme.md — autogen-core package README"
  - "raw:.evolve/raw/autogen-agentchat-readme.md — autogen-agentchat package README"
  - "raw:.evolve/raw/autogen-languages-api.json — language distribution from GitHub API"
  - "raw:.evolve/raw/autogen-commits-api.json — recent commits from GitHub API"
  - "raw:.evolve/raw/autogen-issues-api.json — open issues sample from GitHub API"
evidence_type: raw
_timestamp: "2026-04-28T10:36:06+08:00"
_expiry: "2026-07-28"
confidence: high
independent_sources: 4
---

# AutoGen — 项目事实卡

## 1. 项目身份

- **全称**：AutoGen (microsoft/autogen)
- **定位**：A programming framework for agentic AI（多 Agent AI 应用编程框架）
- **发起方**：Microsoft Research（微软研究院）
- **创建时间**：2023-08-18
- **当前状态**：**维护模式（Maintenance Mode）**，自 2026-04-06 明确官宣
- **License**：CC-BY-4.0（Creative Commons Attribution 4.0 International）
- **GitHub**：https://github.com/microsoft/autogen
- **文档站**：https://microsoft.github.io/autogen/

## 2. 社区活跃度（截至 2026-04-28）

| 指标 | 数值 |
|------|------|
| Stars | 57,512 |
| Forks | 8,665 |
| Open Issues | 793 |
| Watchers | 516 |
| 默认分支 | main |
| 最后推送 | 2026-04-15 |

**版本节奏**：最新稳定版 python-v0.7.5（2025-09-30），此前约 1-2 个月一个 minor 版本。

**维护模式含义**：
- 不再接收新功能或增强
- 由社区管理（community managed）
- 微软推荐新用户迁移至 **Microsoft Agent Framework (MAF)**
- 现有用户可使用迁移指南迁移

## 3. 代码分布

| 语言 | 字节数 | 占比估算 |
|------|--------|---------|
| Python | 4,308,493 | ~64% |
| C# | 1,754,112 | ~26% |
| TypeScript | 868,342 | ~13% |
| 其他 | ~55,000 | ~1% |

**跨语言支持**：Core API 同时支持 Python 和 .NET（C#），通过 protobuf 通信。

## 4. 架构分层（三层设计）

AutoGen v0.3+ 采用了严格的分层架构，与 v0.2 的 conversable agent 模式有本质区别：

```
┌─────────────────────────────────────────────┐
│  Extensions API (autogen-ext)               │  ← 第三方扩展、模型客户端、工具实现
│  - OpenAI/Azure/Anthropic/Ollama 客户端     │
│  - MCP Workbench                            │
│  - Code executors (Docker/Local)            │
│  - Memory backends (Redis, Mem0, ChromaDB)  │
├─────────────────────────────────────────────┤
│  AgentChat API (autogen-agentchat)          │  ← 高层编排：Teams、Agents、预设模式
│  - AssistantAgent, OpenAIAgent              │
│  - RoundRobinGroupChat                      │
│  - SelectorGroupChat                        │
│  - GraphFlow（有向图工作流）                │
│  - MagenticOneGroupChat                     │
├─────────────────────────────────────────────┤
│  Core API (autogen-core)                    │  ← 底层运行时：Actor 模型、消息传递
│  - SingleThreadedAgentRuntime               │
│  - 分布式运行时支持                         │
│  - Event-driven agents                      │
│  - Cross-language (.NET + Python)           │
└─────────────────────────────────────────────┘
```

### 4.1 Core API — Actor 模型运行时

- **设计范式**：Actor model（每位 Agent 是一个 Actor，通过异步消息传递通信）
- **运行时**：`SingleThreadedAgentRuntime`（本地）+ 分布式运行时（云端）
- **核心模块**：code_executor, memory, model_context, models, tool_agent, tools, telemetry
- **跨语言**：Python 与 .NET 通过 protobuf 协议互操作

### 4.2 AgentChat API — 高层编排

为快速原型设计，提供预设行为和团队模式：

| Team 类型 | 模式描述 | 适用场景 |
|-----------|---------|---------|
| `RoundRobinGroupChat` | 轮询发言 | 简单多轮讨论 |
| `SelectorGroupChat` | 模型选择下一位发言者 | 需要智能路由的群聊 |
| `GraphFlow` | 有向图定义执行顺序 | 复杂工作流、DAG、并发 fan-out |
| `MagenticOneGroupChat` | 结构化输出编排 | 复杂任务分解与执行 |

**并发支持**：GraphFlow 支持 `List[str]` 返回多 agent 并发执行（fan-out-fan-in 模式）。

### 4.3 Extensions API — 扩展生态

- **模型客户端**：OpenAI, AzureOpenAI, Anthropic, Ollama, Gemini, Bedrock, Llama API, Qwen 等
- **工具/Workbench**：McpWorkbench (MCP 协议), StaticWorkbench, AzureAISearchTool
- **内存**：ListMemory, RedisMemory, Mem0, ChromaDB embeddings
- **代码执行**：DockerCommandLineCodeExecutor（默认，安全）, LocalCommandLineCodeExecutor
- **遥测**：OpenTelemetry GenAI Traces（create_agent, invoke_agent, execute_tool）

## 5. 核心概念

### 5.1 Agent 类型

| Agent | 功能 | 备注 |
|-------|------|------|
| `AssistantAgent` | 通用助手，支持 tools + memory | 最常用 |
| `OpenAIAgent` | 基于 OpenAI Response API | 支持内置工具 |
| `CodeExecutorAgent` | 执行代码 | 默认 Docker 沙箱 |
| `OpenAIAssistantAgent` | OpenAI Assistant API | v0.7.1 已标记 deprecated |

### 5.2 Agent-as-Tool 模式

AutoGen 支持将 Agent/Team 包装为 Tool：
- `AgentTool(agent)` — 把一个 Agent 变成另一个 Agent 的工具
- `TeamTool(team)` — 把一个 Team 变成工具
- 支持 streaming（v0.6.2+）：内部 Agent/Team 的事件可通过主 Agent 的 stream 透出

### 5.3 MCP 支持

- `McpWorkbench` 支持 MCP (Model Context Protocol) 服务器
- 支持 Streamable HTTP transport
- 支持工具名称和描述覆盖（client-side optimization）

### 5.4 终止条件

- `MaxMessageTermination` — 最大消息数
- `TextMentionTermination` — 检测到特定文本
- 自定义 callable conditions（GraphFlow edges）

## 6. 版本演进关键节点

| 版本 | 时间 | 关键变化 |
|------|------|---------|
| v0.2.x | 2023-2024 | Conversable Agent 模式，社区爆红 |
| v0.3+ | 2024 | **架构大重构**：引入 Core/AgentChat/Extensions 三层 |
| v0.6.0 | 2025-06 | GraphFlow 支持并发 agents；OpenAIAgent 引入 |
| v0.6.2 | 2025-06 | Streaming tools；AgentTool/TeamTool streaming |
| v0.7.1 | 2025-07 | RedisMemory；Teams 可作为 GroupChat participant |
| v0.7.5 | 2025-09 | 最后功能版本（security fixes + GPT-5 support） |
| maintenance | 2026-04 | 官宣维护模式， redirect 至 MAF |

## 7. 已知限制与注意事项

1. **维护模式**：不再添加新功能，安全修复由社区维护
2. **OpenAIAssistantAgent 已废弃**：v0.7.1 标记 deprecated
3. **GraphFlow callable conditions 不可序列化**：实验性功能
4. **AgentTool/TeamTool 并行工具调用有限制**：文档明确警告
5. **AutoGen Studio 非生产就绪**：官方明确声明仅用于原型
6. **MCP 服务器安全风险**：只连接可信 MCP 服务器

## 8. 与光谱其他极的对比定位

| 维度 | AutoGen | CrewAI | LangGraph | smolagents |
|------|---------|--------|-----------|------------|
| 发起方 | Microsoft Research | Joao Moura (独立) | LangChain | Hugging Face |
| 架构范式 | Actor 模型 + 分层 | 角色 + 流程 + 工具 | 状态图 + 节点边 | CodeAgent + tools |
| 抽象层级 | 三层（Core/Chat/Ext） | 单层（Task→Crew） | 单层（Graph） | 单层（Agent） |
| 编排模式 | 轮询/选择器/图/结构化 | 顺序/层级/并行 | 任意状态图 | 单 Agent |
| 跨语言 | Python + .NET | Python | Python | Python |
| 分布式 | Core 层原生支持 | 无 | LangGraph Platform | 无 |
| 当前状态 | **维护模式** | 活跃 | 活跃 | 活跃 |
| Star 数 | 57.5K | ~30K | ~12K | ~22K |

## 9. Evidence Sources

- GitHub repo API: `.evolve/raw/autogen-repo-api.json`
- GitHub releases API: `.evolve/raw/autogen-release-api.json`
- GitHub README: `.evolve/raw/autogen-readme.md`
- Core package README: `.evolve/raw/autogen-core-readme.md`
- AgentChat package README: `.evolve/raw/autogen-agentchat-readme.md`
- Language stats: `.evolve/raw/autogen-languages-api.json`
- Recent commits: `.evolve/raw/autogen-commits-api.json`
- Open issues sample: `.evolve/raw/autogen-issues-api.json`
