# 代码即行动：OpenHands 的软件工程 Agent 架构解剖

## 文章信息

- **slug**: openhands-architecture
- **预估总字数**: 10,000~12,000 中文字
- **目标读者**: 有经验的后端/AI 工程师、技术负责人、架构师
- **系列定位**: 五极长文续篇，专题深潜结构（结构 C），§5 引用首篇坐标系
- **核心差异维度**: 代码执行深度、沙箱安全边界、评审反馈循环、五层产品矩阵

---

## §0 摘要（~1,200 字）

**目标**: 让读者在 2 分钟内判断这篇文章是否值得读。
**核心论点**: OpenHands 不是"又一个聊天 Agent 框架"，而是一个在 Docker Sandbox 中执行真实代码的软件工程 Agent。它的架构设计围绕一个根本问题：如何让 LLM 安全地修改代码库并验证结果。
**三个反直觉发现预告**:
1. OpenHands 的 EventStream 不是"消息队列的别名"，而是一个把所有组件（Agent、Runtime、Frontend）解耦为纯事件生产/消费关系的架构 backbone——这意味着 Frontend 可以在 Runtime 崩溃后继续恢复会话
2. 五层产品矩阵（SDK→CLI→GUI→Cloud→Enterprise）不是简单的"同一套代码打包五次"，而是 1.0.0 重大重构的结果：CLI 拆出独立仓库，SDK 独立为 software-agent-sdk，主仓库聚焦 GUI+Server
3. OpenHands 在 SWE-bench 上的评分（77.6）不是营销数字，而是架构设计（Runtime 可插拔 + 多模型支持 + 事件驱动可恢复）的直接产物——但这个分数掩盖了真实部署中的沙箱配置复杂度

---

## §1 开头钩子："软件工程 Agent"不是聊天机器人的延伸（~1,500 字）

### §1.1 一个被混淆的概念

2024 到 2026 年，技术社区对"Agent"的定义经历了两次膨胀：第一次从"调用工具的 LLM"膨胀到"多 Agent 协作系统"，第二次从"对话系统"膨胀到"软件工程助手"。OpenHands 位于第二次膨胀的中心，但多数讨论仍用第一次膨胀的框架理解它。

Chatbot 和 Software Engineering Agent 的根本差异不在"是否调用工具"，而在**行动的后果是否可逆**。一个聊天 Agent 调用搜索引擎返回错误结果，用户可以忽略它；一个软件工程 Agent 执行 `rm -rf /project/src`，后果可能是不可恢复的。这个差异决定了架构设计的全部关键决策。

### §1.2 两个数字制造的张力

截至 2026 年 4 月，OpenHands 拥有 72,234 个 star，在开源 Agent 框架中排名第一 [ref: facts/openhands-001.md]。但它的核心架构描述——EventStream 事件驱动 + Runtime Sandbox 隔离执行——在中文技术社区中几乎没有深度分析。大多数介绍文章停留在"安装教程"和"功能演示"层面。

另一个数字：OpenHands 在 SWE-bench（软件工程基准测试）上的得分是 77.6 [ref: raw:openhands-readme.md]，高于多数同类项目。但这个分数的架构含义是什么？是什么设计决策让它在真实代码库修改任务上表现更好？这正是本文要回答的。

### §1.3 本文要做什么

本文不教你"如何安装 OpenHands"，而是解剖它的架构设计：EventStream 如何解耦组件、Runtime 如何平衡安全与效率、五层产品矩阵如何对应不同的部署形态。在 §5，我们将把 OpenHands 放入首篇的五维坐标系中，定位它在"控制流显式度"和"生产就绪梯度"上的独特位置。

---

## §2 OpenHands 全景：从 OpenDevin 到五层产品矩阵（~1,800 字）

### §2.1 改名背后的组织变迁

OpenHands 原名 OpenDevin [ref: facts/openhands-001.md]。改名不是品牌包装，而是项目身份的重定义：从"Devin 的开源复刻"转向"独立的软件工程 Agent 平台"。这个重定义在 1.0.0 版本（2025-12-16）中达到高潮——software-agent-sdk 的引入标志着架构从"单体应用"向"可组合平台"的跃迁 [ref: facts/openhands-001.md]。

### §2.2 五层产品矩阵解剖

| 层级 | 形态 | 技术栈 | 部署模式 | 目标用户 |
|------|------|--------|----------|----------|
| L1 SDK | software-agent-sdk | Python | pip install | 框架开发者 |
| L2 CLI | OpenHands-CLI | Python | 终端 | 个人开发者 |
| L3 GUI | Local GUI | React + FastAPI | 本地 Docker | 团队开发者 |
| L4 Cloud | app.all-hands.dev | SaaS | 托管 | 中小团队 |
| L5 Enterprise | 自托管 K8s | Source-available | VPC 内部 | 大企业 |

关键架构决策：1.0.0 将 CLI 拆分为独立仓库，SDK 独立为 software-agent-sdk（678 stars） [ref: raw:openhands-readme.md] [ref: url:https://github.com/OpenHands/software-agent-sdk]。这不是"代码搬家"，而是依赖关系的重构——主仓库从"包含一切"变为"依赖 SDK"，SDK 成为五层共享的引擎层。

### §2.3 版本演进与发布节奏

从 0.62.0（2025-11-11）到 1.6.0（2026-03-30），OpenHands 在 4 个半月内发布了 7 个小版本 [ref: facts/openhands-001.md]。这个节奏比五极中的 CrewAI 和 LangGraph 更激进。高频率发版的代价是什么？从 release notes 观察，1.x 系列的核心变化集中在：模型支持扩展（MiniMax-M2.5、Claude Opus 4.6）、平台集成（Forgejo、Bitbucket）、基础设施（OAuth 2.0、CORS、host networking）——而非架构层面的重新设计。这表明 1.0.0 的架构重构足够坚实，后续迭代是"在稳定地基上盖房子"。

---

## §3 EventStream 架构解剖：事件驱动 backbone 的设计哲学（~2,000 字）

### §3.1 为什么不用直接调用而用事件总线

OpenHands 的核心控制流可以用 5 行伪代码描述 [ref: raw:openhands-core-readme.md]：

```python
while True:
    prompt = agent.generate_prompt(state)
    response = llm.completion(prompt)
    action = agent.parse_response(response)
    observation = runtime.run(action)
    state = state.update(action, observation)
```

但实际实现通过 EventStream 消息传递完成。为什么不用直接函数调用？三个原因：
1. **故障隔离**：Runtime 在 Docker 中执行命令可能崩溃，EventStream 保证 AgentController 不直接依赖 Runtime 进程
2. **可观测性**：所有组件间通信都经过事件总线，天然支持日志、追踪和重放
3. **Frontend 解耦**：前端通过向 EventStream 发送/监听事件参与会话，不需要直接调用后端 API

### §3.2 EventStream 的消息拓扑

```
Agent --Actions--> AgentController --Actions--> EventStream
EventStream --Observations--> AgentController --State--> Agent
EventStream --Actions--> Runtime --Observations--> EventStream
Frontend --Actions--> EventStream
```

这个拓扑的关键特征：**没有中央调度器**。AgentController 不"指挥"Runtime，而是向 EventStream 发布 Action；Runtime 监听 Action 事件，执行后向 EventStream 发布 Observation。这是一个去中心化的 pub/sub 架构，与 AutoGen 的 Actor 模型和 LangGraph 的状态机形成三足鼎立。

### §3.3 与五极控制流范式的对比

| 项目 | 控制流范式 | 通信机制 | 关键差异 |
|------|-----------|----------|----------|
| OpenHands | 事件驱动循环 | EventStream pub/sub | 无中央调度器，组件通过事件总线松耦合 |
| LangGraph | 显式状态图 | Pregel 图引擎 | 开发者定义所有状态转换 |
| smolagents | 黑盒 ReAct | 直接函数调用 | Agent 内部闭环，无外部事件系统 |
| CrewAI | 分布式（多子系统） | Agent 工具 + Flow 事件 | 控制流分散在四个子系统中 |
| AutoGen | Actor 模型 | 异步消息传递 | 严格的 Actor 隔离边界 |
| MAF | 分层（Tier 0→Workflow） | 多种，含 DurableTask | 从黑盒到白盒的分层选项 |

---

## §4 Runtime-Sandbox：代码执行的边界与张力（~1,800 字）

### §4.1 Runtime 的职责边界

Runtime 执行 Action，返回 Observation [ref: raw:openhands-core-readme.md]。Action 包括：编辑文件、运行命令、发送消息。Observation 包括：文件内容、命令输出、错误信息。

Runtime 的可插拔性是关键设计：支持 Docker Sandbox（默认）和本地运行（`RUNTIME=local`）[ref: raw:openhands-agents.md]。这个可插拔性不是"锦上添花"，而是 Dev/Prod 一致的必要条件——开发者在本地用 local runtime 快速迭代，生产环境用 Docker runtime 保证隔离。

### §4.2 Docker Sandbox 的安全模型

Sandbox 在 Docker 容器中执行命令 [ref: raw:openhands-core-readme.md]。安全边界由 Docker 提供，而非 OpenHands 自研。这意味着：
- 优势：继承 Docker 的成熟隔离机制，无需重新发明轮子
- 风险：Docker 的配置复杂度（volume 挂载、网络模式、权限设置）直接传递到 OpenHands 的部署复杂度

1.3.0 引入 host networking mode [ref: facts/openhands-001.md] 是一个值得关注的信号：某些场景下容器网络隔离反而是障碍（如需要访问本地服务的开发环境），host mode 提供了绕过选项——但也削弱了安全边界。

### §4.3 与五极沙箱方案的对比

| 项目 | 沙箱方案 | 执行环境 | 安全边界 |
|------|----------|----------|----------|
| OpenHands | Docker + local 可选 | 容器/宿主机 | Docker 隔离 |
| smolagents | E2B / Docker / WASM | 第三方/容器/WASM | 依赖外部服务 |
| AutoGen | DockerCommandLineCodeExecutor | 容器 | Docker 隔离 |
| MAF | CodeAct / Hyperlight（proposed） | 轻量级虚拟化 | Hyperlight 微隔离 |
| LangGraph | 无内置，依赖部署环境 | 无 | 无 |
| CrewAI | 无内置 | 无 | 无 |

OpenHands 和 AutoGen 都选择 Docker 作为默认沙箱，但 OpenHands 的 Runtime 可插拔设计给了开发者更多选择。smolagents 的 E2B 集成提供了更强的安全保证（第三方托管沙箱），但引入了外部依赖和网络延迟。

---

## §5 与五极的对比：OpenHands 在坐标系中的位置（~1,500 字）

### §5.1 控制流显式度：中间偏左

OpenHands 的控制流不是完全黑盒（LLM 决定一切），也不是完全白盒（开发者定义状态图）。AgentController 驱动主循环，但 LLM 决定每一步的 Action [ref: raw:openhands-core-readme.md]。开发者可以配置 Agent 的行为（通过 `.agents/` 目录的配置文件），但不能像 LangGraph 那样精确控制每一步的状态转换。

在五维坐标系的"控制流显式度"维度上，OpenHands 位于 smolagents（最左）和 LangGraph（最右）之间，更接近 CrewAI 的位置——但 CrewAI 的控制流分散在多个子系统中，OpenHands 的控制流集中在 AgentController + EventStream 中，认知模型更统一。

### §5.2 生产就绪梯度：领先

OpenHands 在五极之外的独特优势是**五层产品矩阵的完整性**。从 pip-installable SDK 到企业级 K8s 自托管，OpenHands 提供了比其他任何单一框架更完整的部署光谱 [ref: raw:openhands-readme.md]。

但"完整性"不等于"每个层级都最优"。Cloud 层的免费试用使用 Minimax 模型 [ref: raw:openhands-readme.md]，这对需要 Claude/GPT 质量的场景是限制。Enterprise 层的 source-available License [ref: raw:openhands-readme.md] 要求购买商业许可才能运行超过一个月——这比 MIT 核心代码更严格。

### §5.3 新增维度：代码执行深度

首篇五维坐标系没有完整捕捉 OpenHands 的独特性。建议增加第 6 维：**代码执行深度**——测量框架是否支持在隔离环境中执行真实代码、修改文件系统、运行测试套件。

| 框架 | 代码执行深度 | 说明 |
|------|-------------|------|
| OpenHands | 高 | Docker Sandbox 执行任意命令，修改真实文件系统 |
| smolagents | 中 | CodeAgent 执行 Python 代码，但主要面向工具调用 |
| AutoGen | 中 | Docker 代码执行器，但偏向脚本执行 |
| LangGraph | 低 | 无内置代码执行，依赖外部工具 |
| CrewAI | 低 | 无内置代码执行 |
| MAF | 中 | CodeAct 架构（proposed），Hyperlight 沙箱 |

---

## §6 实践建议：何时选择 OpenHands（~1,000 字）

### §6.1 适用场景

- 需要 Agent 在隔离环境中执行真实代码（不只是调用 API）
- 需要 GUI + CLI + SDK 三种交互模式的团队
- 需要渐进式部署（从本地开发到企业自托管）的组织
- SWE-bench 类任务：代码库理解、bug 修复、功能实现

### §6.2 不适用场景

- 只需要简单工具调用（smolagents 更轻量）
- 需要精确控制流定义（LangGraph 更适合）
- 完全零锁定的需求（Enterprise 层 source-available 有商业许可限制）
- Python < 3.12 的环境（OpenHands 要求 >=3.12）

### §6.3 决策树

```
需要 Agent 执行真实代码？
  ├─ 否 → 考虑 smolagents 或 LangGraph
  └─ 是 → 需要 GUI 界面？
           ├─ 否 → OpenHands SDK + CLI
           └─ 是 → 需要团队协作？
                    ├─ 否 → OpenHands Local GUI
                    └─ 是 → OpenHands Cloud / Enterprise
```

---

## 图片规划

| 图号 | 位置 | 内容 | 提示词包 |
|------|------|------|----------|
| 图 1 | §1 | 聊天 Agent vs 软件工程 Agent 的后果可逆性对比 | image-prompts/openhands-architecture.md 图 1 |
| 图 2 | §2 | 五层产品矩阵金字塔图 | image-prompts/openhands-architecture.md 图 2 |
| 图 3 | §3 | EventStream 消息拓扑流程图 | image-prompts/openhands-architecture.md 图 3 |
| 图 4 | §3 | 六项目控制流范式对比光谱 | image-prompts/openhands-architecture.md 图 4 |
| 图 5 | §4 | Runtime-Sandbox 安全边界示意图 | image-prompts/openhands-architecture.md 图 5 |
| 图 6 | §5 | 六维坐标系（五维+代码执行深度）定位图 | image-prompts/openhands-architecture.md 图 6 |
| 封面 | 文章顶部 | OpenHands 架构解剖概念封面 | image-prompts/openhands-architecture.md 封面 |

---

## 引用来源清单

- facts/openhands-001.md — OpenHands 项目事实卡
- raw:openhands-readme.md — 项目 README
- raw:openhands-core-readme.md — 核心模块 README
- raw:openhands-agents.md — 贡献者指南
- raw:openhands-repo-api.json — GitHub 仓库元数据
- raw:openhands-releases-api.json — Release 历史
- articles/published/five-pole-agent-frameworks.md — 首篇五极长文（§5 对比引用）
