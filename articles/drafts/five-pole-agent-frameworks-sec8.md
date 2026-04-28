## §8 设计取舍与失败模式（~2,000 字）

五个项目的设计哲学截然不同，但它们共享一个被宣传话语掩盖的结构性困境：每个框架都在某个版本中声称"简单"，但代码量、子系统数和概念层级都在持续增长。本节逐一拆解每个项目的核心张力，并从中提取一个跨项目的共同模式。

---

### §8.1 五个项目各自的结构性张力

**CrewAI："Lean" 口号与 519 个核心文件的现实**

CrewAI 的 README 将自身定位为 "lean, lightning-fast Python framework" [ref: facts/crewai-001.md]。这个定位在 2023 年项目初创时或许成立——早期版本仅包含 Agent、Task、Crew 三个核心概念。但截至 2026 年 4 月，CrewAI 的 `lib/crewai/src/crewai/` 目录下已累积 519 个核心 Python 文件，覆盖 15 个以上独立子系统 [ref: facts/crewai-001.md]。

这种膨胀不是无序增长，而是功能压力下的结构性蔓延。LLM 抽象层需要支持 10+ 提供商，Memory 需要向量数据库后端，RAG 需要嵌入模型，A2A 需要协议完整实现，MCP 需要三种传输方式，Events 需要总线机制，Telemetry 需要 OpenTelemetry 集成，Security 需要指纹验证，Flows 需要事件驱动路由——每一个子系统都有独立的架构理由，但它们的集合已经远超 "lean" 一词所能描述的范围 [ref: facts/crewai-001.md]。

更深层的张力来自 Process 抽象的设计选择。`process.py` 仅 11 行代码，只定义了 `sequential` 和 `hierarchical` 两个 enum 值，连 `consensual` 都注释为 TODO 从未实现 [ref: facts/crewai-001.md]。这个过薄的抽象层将编排复杂度推给了三个互不统属的子系统：Agent delegation 工具（`DelegateWorkTool`/`AskQuestionTool`）、Flow 框架（3,572 行的 `@start`/`@listen`/`@router` 事件驱动系统）和 Task `context` 依赖链 [ref: facts/crewai-001.md]。开发者需要同时掌握四个独立的心理模型才能理解 CrewAI 的完整控制流，这与 "lean" 所承诺的低认知税之间存在真实的落差。

Flow 框架的引入（v1.x 系列）进一步加剧了这种张力。CrewAI Flows 提供事件驱动的工作流能力，与 LangGraph 的状态机图产生了直接功能重叠 [ref: facts/crewai-001.md]。两个不同范式（角色编排 vs 事件驱动图）共存于同一仓库，各自有独立的 API 风格和执行语义，形成了框架内部的路线竞争。

**LangGraph：显式控制的认知税与依赖管理复杂度**

LangGraph 的设计哲学建立在一条清晰的信念上：开发者应该完全掌控状态流转。Pregel 执行引擎、显式 nodes/edges/state channels、原生 checkpointing——这些能力使 LangGraph 成为控制流显式度的光谱右端 [ref: facts/langgraph-001.md]。但这个设计选择附带了一笔认知税：开发者必须理解图论概念（节点、边、状态通道、Pregel 执行模型）才能写出第一个工作流 [ref: facts/langgraph-001.md]。

这笔认知税在复杂工作流上物有所值，但在简单任务上构成了过度工程化风险。如果一个 Agent 只需要调用两三个工具并返回结果，LangGraph 的图抽象相当于用状态机描述一个线性脚本——与 Anthropic "Building Effective Agents" 中 "简单优于复杂" 的警告形成直接冲突 [ref: facts/langgraph-001.md]。这种冲突不是理论性的：LangGraph 的 512 个 open issues 中，相当比例来自新手开发者在简单场景下的困惑 [ref: facts/langgraph-001.md]。

依赖管理是另一个隐性成本。LangGraph 采用 monorepo 多包独立版本策略：`langgraph` 核心、`langgraph-prebuilt`、`langgraph-checkpoint`、`langgraph-cli` 各自独立发版 [ref: facts/langgraph-001.md]。这种策略在框架复杂度高的前提下有其合理性，但它将版本兼容性检查的责任转嫁给了用户。一个生产环境需要同时追踪四个独立版本号的兼容性矩阵，这在快速迭代期（LangGraph 几乎每日发布）构成了实质性的维护负担。

**smolagents：极简口号下的代码膨胀与维护可持续性风险**

smolagents 的 README 声称核心逻辑 "fits in ~1,000 lines of code" [ref: facts/smolagents-001.md]。2026 年 4 月的实际测量显示，`agents.py` 总行数为 1,814 行，除去空行与注释后为 1,481 行 [ref: facts/smolagents-001.md]。"~1,000 行" 作为一个营销数字已经失效，但框架仍在其宣传中保留这一表述——这种文档声明与实际代码量之间的偏差，损害的不是功能完整性，而是技术可信度。

更隐蔽的风险来自安全设计。smolagents 提供四级沙箱方案：托管云沙箱（E2B/Blaxel/Modal）、容器沙箱（Docker）、WASM 沙箱（Pyodide + Deno）和本地执行（LocalPythonExecutor） [ref: facts/smolagents-001.md]。官方文档明确声明 LocalPythonExecutor "is **not a security sandbox**" 且 "must not be used as a security boundary" [ref: facts/smolagents-001.md]。但在快速原型场景中，大量开发者会默认使用本地执行器（它是 import 后的零配置默认选项），从而在不知情中暴露于任意代码执行风险。这不是框架的设计缺陷，而是 "极简" 用户体验与 "安全" 默认配置之间的结构性张力——最简路径恰好是最不安全的路径。

长期可维护性构成第三个风险维度。smolagents 拥有 26,939 个 star 和 517 个 open issues，但核心维护者仅 2 人 [ref: facts/smolagents-001.md] [ref: facts/smolagents-001.md]。最新 release v1.24.0 发布于 2026 年 1 月 16 日，距本文写作已过去 3.5 个月 [ref: facts/smolagents-001.md]。在 issue 积压速度超过处理能力的条件下，一个高关注度、低维护带宽的项目面临社区贡献质量下降和核心维护者倦怠的双重压力。

**AutoGen：维护模式下的遗产衰减**

AutoGen 在 2026 年 4 月 6 日进入维护模式——不再接收新功能，仅由社区维护安全修复 [ref: facts/autogen-001.md]。对于拥有 57,512 个 star 和 8,665 个 fork 的项目而言，这个状态转换意味着大量基于 AutoGen 构建的生产系统正在失去官方技术支持背书。

维护模式的直接影响是已知缺陷的冻结。AutoGen v0.7 文档明确列出 GraphFlow callable conditions 不可序列化、AgentTool/TeamTool 并行工具调用有限制、AutoGen Studio 非生产就绪等实验性功能的稳定性问题 [ref: facts/autogen-001.md]。这些问题在维护模式下不会再获得官方修复——社区维护者的资源有限，优先级自然集中在安全补丁而非功能完善。对于正在评估 AutoGen 的团队，这意味着选择 AutoGen 不是选择了一个"成熟稳定"的框架，而是选择了一份冻结的代码基和一份官方建议的迁移路径。

**MAF：极新框架的稳定性鸿沟**

MAF 是五极中最年轻的项目——2025 年 4 月 28 日创建，距本文写作刚满一年 [ref: facts/maf-001.md]。这个年轻度带来了两个直接后果。

第一，核心扩展包仍处于 pre-release 状态。`agent-framework-orchestrations`（高层编排构建器）、`agent-framework-durabletask`（持久化工作流）和 `agent-framework-devui`（开发调试 UI）均需要 `--pre` 标志安装 [ref: facts/maf-001.md]。这意味着 MAF 宣传的分层控制能力中，Tier 2 级别的关键组件尚未达到稳定版标准。一个企业级框架的核心编排和持久化能力处于 pre-release，与它的企业级定位之间存在明显的成熟度缺口。

第二，关键架构决策尚未落地。CodeAct 代码执行方案（ADR 0024）状态仍为 proposed，未进入 accepted [ref: facts/maf-001.md]。这意味着 MAF 的代码执行策略尚未最终定型，未来可能出现 breaking changes。MAF 的 commit 历史中可见 `[Breaking]` 标记，确认了 API 仍在演进而未稳定 [ref: facts/maf-001.md]。

生态锁定则构成另一层隐性门槛。MAF 的 quickstart 示例默认使用 Azure CLI + Microsoft Foundry 配置，README 含第三方系统免责声明（使用非 Azure 模型需自行承担风险）[ref: facts/maf-001.md]。这不是缺陷，而是明确的产品定位信号——MAF 是微软 Azure AI 平台的客户端框架。但对于非 Azure 用户，这个默认值意味着额外的配置复杂度和心理成本。

---

### §8.2 跨项目共同困境：Agent 框架的边界模糊化

五个项目各自有不同的结构性张力，但这些张力共享一个共同的深层原因：Agent 框架的边界正在模糊化。

2023 年的 "Agent 框架" 几乎专指 "一个让 LLM 调用工具的库"。到 2026 年，同一个标签下已经混杂了至少五种不同的技术形态：极简工具调用封装（smolagents Tier 0）、角色驱动的多 Agent 协作平台（CrewAI）、显式状态机图引擎（LangGraph）、Actor 模型消息传递运行时（AutoGen）、分层企业级 Agent 基础设施（MAF）。每一个框架都在原始边界之外承担了新的职责——CrewAI 从角色编排扩展为事件驱动工作流引擎，LangGraph 从状态机扩展为持久化执行平台，smolagents 从极简封装扩展为多模态工具链，MAF 从多 Agent 运行时扩展为全栈托管方案。

这种边界模糊化的驱动力来自真实的市场需求：用户不只想"让 LLM 调用工具"，他们想要持久化、可观测性、安全沙箱、部署托管、人机交互、多协议支持——这些能力原本属于工作流引擎、可观测性平台和 DevOps 工具的领地。Agent 框架向这些领地扩张是商业逻辑的必然结果，但扩张的代价是"极简"承诺的侵蚀。

CrewAI 的 519 个文件、LangGraph 的 518 MB 仓库、smolagents 的 1,814 行 `agents.py`——这些数字不是设计失误，而是功能压力下的自然结果。五个项目都在某处声称"简单"，但代码量、子系统数和概念层级都在持续增长。这个困境没有简单的解法：收缩功能意味着失去用户，扩张功能意味着背叛"极简"承诺。2026 年的 Agent 框架选型，本质上是选择"在哪个维度上接受膨胀"——而非选择"一个不会膨胀的框架"。

> **图 6 插入位置**："极简框架"的设计张力循环图，五个项目围绕"极简承诺 vs 功能膨胀"中心主题的循环关系。详见 `image-prompts/five-pole-agent-frameworks.md` 图 6。
