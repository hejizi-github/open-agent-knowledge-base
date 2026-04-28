# 记忆幻象：Agent 框架的「记忆」承诺与工程现实

## §4 误区三：Checkpoint = 状态 = 记忆（~2,000 字）

### §4.1 LangGraph 的「记忆」承诺

LangGraph 的 README 在 "Why use LangGraph?" 一节中列出五项核心能力，其中第三项是：

> "**Comprehensive memory** — Create truly stateful agents with both short-term working memory for ongoing reasoning and long-term persistent memory across sessions." [ref: facts/langgraph-001.md]

这段描述制造了一个清晰的认知框架：LangGraph 提供「短期记忆」（单 session 的 working memory）和「长期记忆」（跨 session 的 persistent memory），两者构成一个完整的记忆系统。对工程师来说，这意味着「记忆问题已经内建于框架，无需额外引入 Mem0 或 Letta」。

但同一段介绍中的第一项能力揭示了另一回事：

> "**Durable execution** — Build agents that persist through failures and can run for extended periods, automatically resuming from exactly where they left off." [ref: facts/langgraph-001.md]

"Durable execution" 不是记忆的营销用语，而是一个有精确技术含义的术语。在分布式系统和数据库领域，durable execution 指的是「执行状态在故障后仍可恢复」——类似于数据库的预写日志（WAL）或工作流引擎的 checkpoint 机制。它的核心目标是**保证执行不中断**，而不是**让 Agent 学会什么**。

LangGraph 通过 `langgraph-checkpoint` 子包（独立版本号 4.0.3）实现这一能力 [ref: facts/langgraph-001.md]。每个步骤完成后，Pregel 执行引擎自动保存状态快照；当流程因网络中断、节点异常或人为暂停而失败时，系统从最近的 checkpoint 恢复，继续执行。

问题就在这里：README 把 "durable execution" 和 "comprehensive memory" 列为两个独立的能力，但底层实现中，所谓的 "long-term persistent memory across sessions" 实质上就是 checkpoint 的跨 session 持久化。**同一个技术机制（checkpoint）被包装成了两个不同的用户价值承诺（执行恢复 + 长期记忆）。**

### §4.2 Checkpoint 的真实语义

要理解 checkpoint 与记忆的本质差异，需要先看 checkpoint 保存了什么。

LangGraph 的 Pregel 引擎中，状态通过 state channels 传递。每个节点（node）接收一组输入 state，执行后产生一组输出 state，这些 state 被写入 channels [ref: facts/langgraph-001.md]。Checkpoint 在每个步骤边界捕获的是：

- 当前执行到哪个节点（图遍历位置）
- 各 state channel 中的变量值
- 待处理的边（edges）和条件分支结果
- Human-in-the-loop 的暂停状态（如有）

这些内容构成了一个**执行状态的完整快照**。它的设计目标是：如果此刻服务器崩溃，重启后能从快照继续，用户不会感知到中断。这与数据库事务的 ACID 属性中的 Durability 是同一类问题——保证已完成的操作不会丢失。

但 checkpoint 保存的内容不包含：

- Agent 从对话中提取的用户偏好（如「用户喜欢简洁的回答」）
- Agent 对世界模型的更新（如「这个 API 在 v2 中已弃用」）
- Agent 对自身策略的调整（如「上次用工具 X 失败了，下次先尝试工具 Y」）
- 跨用户的模式识别（如「这类查询往往需要调用搜索工具」）

这些内容——即我们所理解的「Agent 学到了什么」——不在 checkpoint 的语义范围内。Checkpoint 是**执行轨迹的存档**，不是**学习成果的积累**。

用一个类比来澄清：数据库的 binlog 记录了每一条 SQL 的执行顺序和参数，使主从复制和故障恢复成为可能。但 binlog 不是数据库的「知识」——它不会让数据库「学会」哪些查询该走索引、哪些表该分区。Checkpoint 之于 Agent，正如 binlog 之于数据库：保证执行的连续性，不提供学习的语义。

### §4.3 语义鸿沟：durable execution vs learnable memory

把 checkpoint 称为 "long-term memory" 之所以是一个误区，是因为这两个概念在五个关键维度上存在不可调和的差异。

**维度一：时间方向。**

Checkpoint 是**向后恢复**的机制。它的价值在故障发生时才显现——「回到上次正常的状态」。它不关心过去十几次 session 中 Agent 积累了什么知识，只关心「上次执行到哪儿」。

记忆是**向前积累**的机制。它的价值在日常交互中持续显现——「基于过去所有经验，这次我要怎么做」。Mem0 的 ADD-only 策略明确体现了这种向前积累的设计意图：每一条新记忆都是历史之上的增量，旧记忆不被覆盖，系统随着时间推移拥有越来越丰富的用户画像 [ref: facts/mem0-001.md]。

**维度二：内容范围。**

Checkpoint 保存的是**执行状态**——变量值、节点位置、待处理边。这些内容对 Agent 的「认知」没有意义。一个 checkpoint 可能包含 `current_node="tool_call_3"` 和 `pending_edges=["success", "failure"]`，但这些信息在恢复后仅用于「继续执行」，不会被 Agent 的推理过程主动引用。

记忆保存的是**学习到的知识**——用户偏好、事实信念、策略调整。Letta 的 `Human` Block 存储「用户是素食主义者」，`Persona` Block 存储 Agent 的自我角色定义 [ref: facts/letta-001.md]。这些内容在每次 LLM 调用时直接存在于上下文中，持续影响 Agent 的行为选择。

**维度三：更新触发。**

Checkpoint 每步**自动保存**，无需判断「这是否值得记」。它的触发条件是执行步骤的完成，而不是信息的重要性。即使某一步只是做了一个无意义的空操作，checkpoint 仍然会记录。

记忆需要**选择性提取**。Mem0 的 `add()` 方法包含一个 7 阶段流水线，其中 Phase 2 是 LLM 单通道提取——模型判断哪些内容值得作为记忆保留 [ref: facts/mem0-001.md]。Letta 的 Agent 通过 `core_memory_append` 工具显式决定写入什么 [ref: facts/letta-001.md]。两种设计都体现了「记忆不是无差别存档，而是有选择的提炼」。

**维度四：使用方式。**

Checkpoint 在**故障时自动使用**，用户对它的存在几乎无感知。正常情况下，Agent 不会「读取」checkpoint 来辅助决策——checkpoint 是运维层面的机制，不是推理层面的输入。

记忆在**推理时主动注入**。Mem0 的 `search()` 在每次对话前检索相关记忆并注入系统 prompt [ref: facts/mem0-001.md]。Letta 的 Block 直接常驻于上下文窗口，每次 LLM 调用都能「看到」自己的记忆 [ref: facts/letta-001.md]。记忆是 Agent 认知输入的一部分，不是后台的故障恢复工具。

**维度五：跨 session 语义。**

这是最关键的差异。LangGraph 的 "long-term persistent memory across sessions" 听起来像是跨 session 学习，但它的实际语义是：**同一个工作流实例在多次调用之间的状态延续**。如果用户今天启动了 Agent A，明天用同一个 thread ID 继续，checkpoint 让 Agent A 从昨天的状态继续执行。但如果在第三天启动 Agent B（不同的 thread ID），Agent B 不会继承 Agent A 的任何「经验」——除非开发者显式将 checkpoint 中的某些状态导出为可共享的知识。

真正的跨 session 记忆要求：不同实例、不同 thread、甚至不同 Agent 之间能够共享学习到的知识。Mem0 的 `user_id` 参数使同一用户的记忆跨所有会话可用 [ref: facts/mem0-001.md]。Letta 的 Archival Memory 允许 Agent 从长期存储中检索过去任何 session 的信息 [ref: facts/letta-001.md]。Checkpoint 不提供这种跨实例知识共享的语义。

### §4.4 为什么这种混淆有害

把一个执行恢复机制包装成长期记忆，对工程决策的损害是隐性的。

**场景：客服 Agent 的跨 session 用户体验。** 一个团队使用 LangGraph 构建客服 Agent，看到 README 承诺 "long-term persistent memory across sessions"，认为 Agent 会自动记住回头客的历史问题。他们上线了服务。用户第一次咨询退货流程，Agent 引导完成。三天后同一用户再次咨询，问的是退款进度。由于使用了不同的 thread ID（每次对话新建一个 session），Agent 没有任何关于「这个用户三天前咨询过退货」的信息。它对用户的认知从零开始。

这不是 LangGraph 的缺陷——LangGraph 从未承诺 Agent 会「学习」用户历史。它的承诺是「持久化执行状态」，而这个场景中的问题恰恰是「执行状态没有可继承的知识」。但 README 中的 "long-term persistent memory" 措辞让团队产生了错误的期望，直到用户投诉「Agent 每次都不记得我」时才意识到语义鸿沟。

更深层的问题在于，这种概念借用**掩盖了真正的工程需求**。当团队发现 checkpoint 不能解决跨 session 记忆问题时，他们面临的选择不是「在 LangGraph 中开启某个开关」，而是「引入一个独立记忆层（Mem0/Letta）或自行实现记忆系统」。如果 README 明确区分 "durable execution checkpoint" 和 "learnable memory"，团队会在项目初期就做出正确的架构决策，而不是在中途被迫重构。

### §4.5 结论：执行持久化 ≠ 知识学习

LangGraph 的 checkpoint 是一个设计精良的 durable execution 机制，在「保证长流程不中断」这一问题上无可替代。但它不是记忆系统——它不提取知识、不维护信念、不累积经验、不跨实例共享学习成果。

评估一个框架的「长期记忆」能力时，不要问「它有没有 checkpoint」或「它能不能保存 state」。要问：

- 它的持久化内容是否包含从交互中提取的**结构化知识**？
- 它是否支持跨实例、跨 thread 的**知识共享**？
- 它是否有**选择性提取**机制（判断什么值得记）？
- 它是否在推理时**主动注入**学习到的内容？

如果答案都是「否」，那么这个框架提供的不是记忆，只是**执行状态的存档服务**——有价值，但与记忆不是一回事。

> **图 4：Checkpoint（执行恢复）与 Learnable Memory（知识学习）的语义鸿沟**
>
> 左右两个平行系统：左侧「Durable Execution」展示 checkpoint 的流程（执行→快照→故障→恢复→继续执行），内容标注为「节点位置、变量值、待处理边」；右侧「Learnable Memory」展示记忆流程（交互→提取→存储→检索→注入推理），内容标注为「用户偏好、事实信念、策略调整」。中间用断裂线连接，标注「同一个技术机制被包装成两个概念」。提示词详见 `image-prompts/agent-memory-misconceptions.md` 图 4。
