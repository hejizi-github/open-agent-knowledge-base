## §3 EventStream 架构解剖：事件驱动 backbone 的设计哲学（~2,000 字）

§2 揭示了 OpenHands 的五层产品矩阵如何在组织层面解耦——SDK、CLI、GUI 各自独立演进。但组织解耦只是表象，技术层面的解耦才是支撑五层产品共享同一套引擎的核心机制。这个机制就是 EventStream。

### §3.1 从伪代码到事件总线：为什么不用直接函数调用

OpenHands 的核心控制流可以用 5 行伪代码概括 [ref: raw:openhands-core-readme.md]：

```python
while True:
    prompt = agent.generate_prompt(state)
    response = llm.completion(prompt)
    action = agent.parse_response(response)
    observation = runtime.run(action)
    state = state.update(action, observation)
```

这个伪代码传达的直观印象是：AgentController 直接调用 Agent、LLM、Runtime，形成一条顺序执行链。但 OpenHands 的实际实现中，这条链中的每一步都不是直接函数调用，而是通过 EventStream 的消息传递完成 [ref: raw:openhands-core-readme.md]。Agent 产出的 Action 不是直接传给 Runtime，而是发布到 EventStream；Runtime 执行后的 Observation 不是直接返回给 AgentController，而是发布到 EventStream 等待监听者消费。

这个设计选择——用事件总线替代直接调用——在 Agent 框架领域并不常见。多数框架采用直接调用模式：smolagents 的 ReAct 循环中，Agent 直接调用工具函数 [ref: facts/smolagents-001.md]；LangGraph 的 Pregel 引擎中，节点函数通过图边直接传递状态 [ref: facts/langgraph-001.md]。OpenHands 选择事件总线的理由是什么？

**第一个理由是故障隔离。** Runtime 在 Docker 容器中执行真实代码——`rm -rf`、`pip install`、`pytest` 等命令——任何一条命令都可能导致容器崩溃或进入不可恢复状态。如果 AgentController 直接调用 Runtime，Runtime 的崩溃会直接拖垮 AgentController，进而导致整个会话丢失。EventStream 作为中间层，使 AgentController 和 Runtime 成为独立进程：Runtime 崩溃后，EventStream 中已发布的事件不会丢失，AgentController 可以在 Runtime 重启后从断点恢复。这种故障隔离不是"锦上添花"，而是软件工程 Agent 的必需——因为 Runtime 执行的是真实代码，崩溃概率远高于纯 API 调用场景 [ref: facts/openhands-001.md]。

**第二个理由是可观测性。** 所有组件间通信都经过 EventStream，这意味着系统的全部交互历史都以事件序列的形式被保留。调试一个失败的 Agent 任务时，开发者可以重放 EventStream 中的事件序列，精确复现 Agent 的决策路径。直接调用模式下，调用栈和返回值是瞬态的，除非额外植入日志，否则无法回溯。EventStream 将这种"可回溯性"内建在架构中，而非作为外部工具附加 [ref: raw:openhands-core-readme.md]。

**第三个理由是 Frontend 解耦。** OpenHands 的 GUI 前端是一个独立的 React 应用 [ref: facts/openhands-001.md]。如果前端需要直接调用后端 API 来获取 Agent 状态，那么每次架构调整（如新增一种 Action 类型）都需要同步修改前后端接口。EventStream 模式下，前端只需监听事件流：Agent 发布了新的 Action，前端收到事件后更新 UI；Runtime 发布了新的 Observation，前端收到事件后追加到聊天记录。前端不需要知道 Action 的具体类型，也不需要知道 Runtime 的实现细节——它只消费事件。这种解耦使前端可以独立演进，也为未来新增交互模式（如 WebSocket 推送、CLI 实时输出）提供了统一的底层支撑。

### §3.2 EventStream 的消息拓扑

OpenHands 官方文档用一段 mermaid 图描述了 EventStream 的消息拓扑 [ref: raw:openhands-core-readme.md]：

```
Agent --Actions--> AgentController --Actions--> EventStream
EventStream --Observations--> AgentController --State--> Agent
EventStream --Actions--> Runtime --Observations--> EventStream
Frontend --Actions--> EventStream
```

这段拓扑图有一个关键特征值得仔细解读：**没有中央调度器**。AgentController 不是"指挥官"，不向 Runtime 发送"执行这个命令"的直接指令；它只是向 EventStream 发布一个 Action 事件。Runtime 作为一个独立的事件消费者，监听 EventStream 中的 Action 事件，执行后向 EventStream 发布 Observation 事件。AgentController 监听 Observation 事件，更新 State，再驱动 Agent 产出下一个 Action。

这个拓扑的去中心化程度在 Agent 框架中处于较高水平。对比一下：AutoGen 的 Actor 模型中，每个 Agent 是一个 Actor，消息在 Actor 之间直接传递 [ref: facts/autogen-001.md]——Actor 之间没有共享的总线，通信是点对点的。LangGraph 的 Pregel 引擎中，开发者预先定义状态转换图，每个节点函数知道它的输入来自哪个节点、输出发往哪个节点 [ref: facts/langgraph-001.md]——控制流是白盒的、静态的。OpenHands 的 EventStream 则介于两者之间：组件通过共享总线通信（类似 Actor 模型的间接寻址），但没有预设的拓扑结构（类似 Pregel 的图边），事件的流向由运行时的发布/订阅关系动态决定。

Frontend 在拓扑中的位置尤其值得关注。Frontend 不是"被动展示层"，而是 EventStream 的平等参与者：它可以向 EventStream 发布 Action 事件（如用户输入的消息），也可以监听 EventStream 中的 Observation 事件（如 Agent 的执行结果）。这意味着 Frontend 可以在 Runtime 崩溃后继续工作——用户仍然可以浏览历史事件、发送新消息；Runtime 恢复后，EventStream 中的新事件会自然流入前端。这种"Frontend 不依赖 Runtime 存活"的特性，是事件驱动架构在可用性层面的直接收益。

### §3.3 与五极控制流范式的对比

| 项目 | 控制流范式 | 通信机制 | 关键差异 |
|------|-----------|----------|----------|
| OpenHands | 事件驱动循环 | EventStream pub/sub | 无中央调度器，组件通过事件总线松耦合；故障可恢复 |
| LangGraph | 显式状态图 | Pregel 图引擎 | 开发者定义所有状态转换；控制流白盒化 |
| smolagents | 黑盒 ReAct | 直接函数调用 | Agent 内部闭环，无外部事件系统；极简但不可观测 |
| CrewAI | 分布式多子系统 | Agent 工具调用 + Flow 事件 | 控制流分散在四个子系统中，认知模型不统一 |
| AutoGen | Actor 模型 | 异步消息传递 | 严格的 Actor 隔离边界，无共享总线 |
| MAF | 分层（Tier 0→Workflow） | 多种，含 DurableTask | 从黑盒到白盒的分层选项，复杂度高 |

这个对比表揭示了一个反直觉的结论：**OpenHands 的 EventStream 不是"又一个消息队列"，而是对软件工程 Agent 特殊需求的架构回应。** 如果 OpenHands 的任务只是调用外部 API（天气查询、搜索引擎），直接函数调用足够，事件总线反而增加不必要的复杂度。但 OpenHands 的任务是在隔离环境中执行真实代码——代码可能崩溃、可能无限循环、可能修改文件系统。在这种场景下，"执行者崩溃不影响调度者"是一个硬需求，而非可选优化。

从另一个角度观察：OpenHands 的控制流范式在"显式度"光谱上处于中间位置。LangGraph 是最显式的——开发者用代码定义每个状态转换。smolagents 是最隐式的——LLM 决定每一步做什么，开发者无法干预中间过程。OpenHands 介于两者之间：AgentController 驱动主循环（显式），但 LLM 决定每一步的 Action 内容（隐式）。开发者可以配置 Agent 的行为（通过 `.agents/` 目录的配置文件）[ref: facts/openhands-001.md]，但不能像 LangGraph 那样精确控制每一步的状态转换。这种"半显式"设计在软件工程场景中是一种务实的折中：完全显式需要开发者手动定义所有可能的代码操作（不现实），完全隐式则无法保证 Agent 不会执行危险命令（不可接受）。

EventStream 还为 OpenHands 带来了长期演进的优势。1.0.0 引入的 software-agent-sdk 将核心引擎从主仓库提取为独立库 [ref: facts/openhands-001.md]，SDK 的对外接口本质上就是 EventStream 的发布/订阅 API。这意味着任何第三方项目——无论是一个新的 CLI 工具、一个 IDE 插件、还是一个自动化流水线——都可以监听和发布事件，与 OpenHands 的核心引擎交互。事件总线成为了一种"开放协议"，而不仅是一种内部实现细节。

> **图 3 插入位置**：EventStream 消息拓扑流程图。左侧为 Agent → AgentController → EventStream 的 Action 流，中间为 EventStream 总线（hub 形状），右侧为 Runtime → EventStream → Frontend 的 Observation 流。用不同颜色区分 Action（蓝色）和 Observation（绿色）。标注"无中央调度器"的核心特征。详见 `image-prompts/openhands-architecture.md` 图 3。

> **图 4 插入位置**：六项目控制流范式对比光谱。横向光谱从左（黑盒/隐式）到右（白盒/显式），六项目按位置排列：smolagents（最左）→ OpenHands → CrewAI → AutoGen → MAF → LangGraph（最右）。每个项目下方标注其通信机制和关键特征。详见 `image-prompts/openhands-architecture.md` 图 4。
