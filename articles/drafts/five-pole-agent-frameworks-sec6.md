## §6 继承与断裂矩阵：MAF 不是 AutoGen 的改名（~2,800 字）

Microsoft Agent Framework 与 AutoGen 之间的关系，是中文技术社区中误读密度最高的议题之一。几乎所有将 MAF 引入中文读者视野的文章，都使用了"继任者""新版""改名"等措辞。这种简化叙述虽然降低了认知门槛，却掩盖了一次完整的工程哲学转向。本节基于源码级事实和架构文档，用"继承/断裂矩阵"方法论系统拆解两者的真实关系。

---

### §6.1 中文社区的普遍误读

打开任意一篇 2026 年 4 月之后介绍 MAF 的中文技术文章，大概率会见到以下三种表述之一：

- "MAF 是 AutoGen 的继任者，微软把 AutoGen 升级成了 MAF。"
- "AutoGen 改名了，现在叫 Microsoft Agent Framework。"
- "AutoGen 停止维护了，MAF 是它的替代品。"

这三种表述共享一个隐含前提：MAF 与 AutoGen 是同一产品的不同版本，关系类似于 Python 2 与 Python 3，或者 AngularJS 与 Angular。这个前提的成因不难理解：两者来自同一组织（Microsoft）、处于同一技术领域（多 Agent 编排框架）、AutoGen 的 README 已 redirect 至 MAF、核心概念命名高度重叠（Agent / GroupChat / Tool / Memory）。在信息传播链路中，"改名"是最低认知成本的叙事，因此它战胜了更复杂的真相。

但源码级对比揭示的图景完全不同。MAF 的 GitHub 仓库 `microsoft/agent-framework` 并非从 `microsoft/autogen` fork 而来，而是 2025-04-28 独立创建的全新项目 [ref: facts/maf-001.md ## 1. 项目身份]。两者的代码基没有共享提交历史，包结构完全不同，甚至连编程语言比例都发生了显著变化（AutoGen Python 64% / C# 26%，MAF Python 50% / C# 45%）[ref: facts/maf-001.md ## 3. 代码分布] [ref: facts/autogen-001.md ## 3. 代码分布]。这些事实不支持"改名"叙事，而指向一种更深层的关系：概念继承 + 工程断裂。

---

### §6.2 继承关系（5 处）

尽管代码基独立，MAF 确实从 AutoGen 继承了若干核心设计概念。这些继承不是代码层面的复制，而是知识层面的延续——同一批微软工程师将 AutoGen 的实践经验提炼为 MAF 的设计输入。

**继承 1：编排模式命名。** MAF 的 `MagenticBuilder` 与 AutoGen 的 `MagenticOneGroupChat` 在命名上完全一致，且文档明确引用相同的概念来源——Magentic One 结构化任务分解模式。同理，`GroupChatBuilder` 直接继承自 AutoGen 的 `SelectorGroupChat`，两者都是"选择器驱动的群聊"机制：一个模型根据对话上下文动态选择下一位发言 Agent [ref: facts/maf-001.md ### 4.3 编排模式（Orchestrations）] [ref: facts/autogen-001.md ### 4.2 AgentChat API — 高层编排]。这种命名层面的延续性，是"改名误读"的主要视觉证据。

**继承 2：双语言设计。** AutoGen 从 v0.3 起同时支持 Python 和 .NET（C#），通过 protobuf 协议实现跨语言通信。MAF 延续了这一设计方向，但将语言比例从 AutoGen 的 64:26（Python 占优）调整为 50:45（接近均衡），并实现了双语言的独立版本发布（python-1.2.0 与 dotnet-1.3.0 同日发布）[ref: facts/maf-001.md ## 3. 代码分布] [ref: facts/autogen-001.md ## 3. 代码分布]。这意味着 MAF 不是"Python 框架顺便支持 C#"，而是真正的双语言一等公民框架。

**继承 3：Actor 模型运行时。** AutoGen Core API 的底层设计范式是 Actor 模型——每个 Agent 是独立 Actor，通过异步消息传递通信 [ref: facts/autogen-001.md ### 4.1 Core API — Actor 模型运行时]。MAF 的运行时设计延续了这一思想，尽管具体实现已重写。在架构文档中，MAF 的异步消息管道、Agent 隔离边界和事件驱动调度都可以追溯到 AutoGen Core 的设计遗产 [ref: facts/maf-001.md ## 9. 与 AutoGen 的继承与断裂]。

**继承 4：MCP 协议支持。** AutoGen 通过 `McpWorkbench` 支持 MCP（Model Context Protocol），允许 Agent 调用外部 MCP 服务器作为工具 [ref: facts/autogen-001.md ### 5.3 MCP 支持]。MAF 将这一能力升级为原生 MCP 客户端实现，支持 stdio、SSE 和 HTTP 三种传输方式，但协议层面的概念模型——tools/resources/prompts 三要素——直接继承自 AutoGen 的 MCP 集成经验 [ref: facts/maf-001.md ### 5.4 协议支持矩阵]。

**继承 5：核心概念体系。** Agent、GroupChat/Team、Tool、Memory 这四个概念在 AutoGen 和 MAF 中保持了语义一致性。一个熟悉 AutoGen 的开发者，可以在不重新学习概念的情况下理解 MAF 的 80% API 命名。这种概念继承降低了迁移成本，也是微软敢于在 AutoGen README 上放置 redirect 链接的信心来源。

---

### §6.3 断裂与重构（8 处）

与 5 处继承相比，MAF 对 AutoGen 的断裂和重构更为深刻。这些断裂不是"改进版"式的渐进优化，而是工程哲学的根本性转向。

**断裂 1：包结构——从严格分层到扁平导入。** AutoGen v0.3+ 采用严格的三层架构：Core API（autogen-core）、AgentChat API（autogen-agentchat）、Extensions API（autogen-ext）。每一层有明确的依赖方向（上层依赖下层，下层不可依赖上层），第三方扩展必须放在 Ext 层 [ref: facts/autogen-001.md ## 4. 架构分层（三层设计）]。MAF 放弃了这种严格分层，改用扁平的 Tier 0/1/2 + namespace packages 设计：Tier 0 提供基础 Agent API（`from agent_framework import Agent`），Tier 1 提供高级组件（vector_data, observability），Tier 2 按厂商分组连接器（`from agent_framework.openai import ...`）[ref: facts/maf-001.md ### 4.1 三层导入体系（Tier 0/1/2）]。AutoGen 的分层是"架构师视角"的（按抽象层级划分），MAF 的 Tier 是"开发者视角"的（按使用频率和厂商归属划分）。MAF 的设计文档首句明确声明："Developer experience is key"[ref: facts/maf-001.md ### 4.1 三层导入体系（Tier 0/1/2）]。

**断裂 2：工作流——从零到图。** AutoGen 没有原生图工作流能力。`GraphFlow` 虽支持有向图定义，但缺乏 checkpointing、time-travel 和分布式状态管理——这些都被文档标注为实验性或未实现 [ref: facts/autogen-001.md ### 4.2 AgentChat API — 高层编排] [ref: facts/autogen-001.md ## 7. 已知限制与注意事项]。MAF 的 Workflow API 直接引入了完整的 Graph-based 工作流，包含数据流连接、streaming、checkpointing、human-in-the-loop 和 time-travel，功能集合对标 LangGraph [ref: facts/maf-001.md ### 4.4 工作流（Workflows）]。这不是 AutoGen 的"升级"，而是从零开始构建 AutoGen 从未有过的能力。

**断裂 3：持久化——从无到 DurableTask。** AutoGen 不提供内置持久化机制，Agent 状态随进程结束而消失。MAF 通过 `agent-framework-durabletask` 集成了微软 Durable Task 框架，实现 Agent 状态的自动持久化、故障恢复和分布式执行 [ref: facts/maf-001.md ### 4.5 Durable Agents / Durable Workflows]。这一能力使 MAF 从"原型框架"跃迁为"企业级平台"，而 AutoGen 始终停留在原型阶段——官方甚至明确声明 AutoGen Studio"非生产就绪"[ref: facts/autogen-001.md ## 7. 已知限制与注意事项]。

**断裂 4：协议——从单协议到多协议战略。** AutoGen 仅支持 MCP 一种开放协议。MAF 同时支持 MCP、A2A（Google 的 Agent-to-Agent 标准）和 AG-UI（Agent-User Interaction 协议，与 LangGraph/CrewAI/Pydantic AI 互操作）[ref: facts/maf-001.md ### 5.4 协议支持矩阵]。这种多协议战略反映了产品团队的生态野心：MAF 不只想做"Agent 框架"，还想做"Agent 互操作的基础设施"。

**断裂 5：UI——从实验工具到开发环境。** AutoGen Studio 是一个基于 Web 的原型界面，官方明确声明其"仅用于原型"而非生产 [ref: facts/autogen-001.md ## 7. 已知限制与注意事项]。MAF 的 DevUI 则定位为"集成开发调试环境"，支持 Agent 开发、测试、调试和工作流可视化，与代码开发流程深度集成 [ref: facts/maf-001.md ### 6.1 DevUI]。这是从"玩具"到"工具"的质变。

**断裂 6：代码执行——从容器隔离到轻量级虚拟化。** AutoGen 的默认代码执行器是 `DockerCommandLineCodeExecutor`，通过 Docker 容器隔离实现安全沙箱 [ref: facts/autogen-001.md ### 4.3 Extensions API — 扩展生态]。MAF 引入了 CodeAct 架构（ADR 0024，proposed 状态），通过 Hyperlight 轻量级虚拟化沙箱执行模型生成的代码 [ref: facts/maf-001.md ### 6.3 代码执行]。Hyperlight 的启动延迟远低于 Docker，更适合高频工具调用场景。这是执行基础设施的代际跳跃。

**断裂 7：中间件——从零到原生管道。** AutoGen 没有中间件概念，Agent 的请求/响应处理逻辑分散在各组件内部。MAF 原生支持 Middleware 系统，允许开发者在请求/响应管道中插入自定义处理逻辑（认证、日志、异常处理、缓存等），且同时在 Python 和 .NET 中实现 [ref: facts/maf-001.md ### 5.3 Middleware 系统]。这是企业级框架的标志性能力。

**断裂 8：License——从知识共享到商业化友好。** AutoGen 使用 CC-BY-4.0（Creative Commons Attribution），这是一种面向内容和文档的许可，对软件代码的法律保护力弱于常规软件 License [ref: facts/autogen-001.md ## 1. 项目身份]。MAF 改用 MIT License，明确允许商业使用、修改和闭源分发 [ref: facts/maf-001.md ## 1. 项目身份]。这个变更 alone 就揭示了项目身份的根本差异：AutoGen 是研究院的知识共享产出，MAF 是产品团队的商业软件交付。

---

### §6.4 "研究院 → 产品团队"的组织断裂

5 处继承和 8 处断裂的深层解释，藏在项目发起方的组织身份中。

AutoGen 的发起方是 **Microsoft Research**（微软研究院）。研究院的 KPI 是发表高质量论文、在学术社区建立影响力、探索前沿架构范式。Actor 模型、严格分层、跨语言运行时——这些设计选择体现了研究院对"架构优美性"和"学术创新性"的追求。CC-BY-4.0 License、实验性 Studio 工具、维护模式下的社区自治——这些决策符合研究院"发布即完成"的典型节奏。

MAF 的发起方是 **Microsoft 官方产品团队**（非研究院独立项目）。产品团队的 KPI 是开发者采纳率、Azure 平台绑定度、企业客户满意度。扁平导入（"Developer experience is key"）、默认 Azure 集成、DurableTask 持久化、MIT License、DevUI 开发环境——这些设计选择全部服务于"让尽可能多的企业开发者在 Azure 上构建 Agent"这一商业目标 [ref: facts/maf-001.md ## 1. 项目身份] [ref: facts/maf-001.md ## 7. 托管与部署]。

这个组织断裂解释了为什么 8 处技术断裂同时指向同一个方向：从"架构创新优先"转向"开发者体验优先"，从"知识共享"转向"商业交付"，从"原型探索"转向"企业平台"。MAF 继承了 AutoGen 的概念遗产（5 处继承），但用一套完全不同的工程哲学重新实现（8 处断裂）。它不是 AutoGen 的 v1.0 → v2.0 升级，而是一次"研究院原型 → 产品团队重构"的断裂式接力。

**核心结论**：将 MAF 称为"AutoGen 改名"，相当于将 Windows NT 称为"MS-DOS 改名"——两者共享同一组织背景和若干概念遗产，但底层架构、工程目标和产品定位已完全不同。对于正在维护 AutoGen 项目的团队，迁移至 MAF 不是"升级依赖版本"，而是"迁移至一个不同的框架"，需要重新评估架构适配成本。

> **图 4 插入位置**：继承/断裂矩阵可视化图。左侧绿色调"继承"5 项（编排模式/双语言/Actor 模型/MCP/概念命名），右侧橙红色调"断裂"8 项（包结构/工作流/持久化/协议/UI/代码执行/中间件/License），底部横幅"Microsoft Research → Microsoft Product Team"。详见 `image-prompts/five-pole-agent-frameworks.md` 图 4。
