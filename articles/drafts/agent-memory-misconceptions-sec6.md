# 记忆幻象：Agent 框架的「记忆」承诺与工程现实

## §6 实践建议：框架内置、独立层与自建方案的选择（~1,000 字）

前五节的分析最终要落到一个可操作的决策上：你的团队应该使用哪种记忆方案？本节提供一个基于三个问题的决策框架，将抽象的概念辨析转化为具体的工程选择。

### §6.1 决策起点：三个问题

选择记忆方案之前，先回答三个问题。这三个问题的答案组合，决定了你应该停留在框架内置方案、引入独立记忆层，还是自建系统。

**问题一：你的 Agent 需要跨 session 记住什么？**

如果答案仅限于「当前 session 内的工作上下文」——比如多步工作流中的当前状态——那么框架内置的短期记忆已经足够。LangGraph 的 state channels [ref: facts/langgraph-001.md] 和 CrewAI 的 Task context 链 [ref: facts/crewai-001.md] 就是为这类场景设计的。如果需要跨 session 记住用户偏好、积累策略调整或多 Agent 共享世界模型，框架内置方案的天花板很快显现。

**问题二：谁控制记忆的写入？**

开发者精确控制写入时机（如「用户确认订单后写入配送地址」）→ 框架内置或自建。LLM 自动从对话提取（如「Agent 自动记住用户偏好」）→ Mem0 的 ADD-only 流水线 [ref: facts/mem0-001.md]。Agent 自己判断并显式调用工具写入 → Letta 的 `core_memory_append` [ref: facts/letta-001.md]。

**问题三：你的架构起点是什么？**

Agent 已基于某个框架搭建完成 → Mem0 的外挂式 API 成本最低 [ref: facts/mem0-001.md]。Agent 尚在架构设计阶段，且「自我认知」是核心特性 → Letta 的 Block 抽象提供更完整的语义框架 [ref: facts/letta-001.md]。

### §6.2 场景一：框架内置方案足够

满足以下全部条件时，框架内置记忆是最务实的选择：

- Agent 的运行场景以单 session 为主，跨 session 状态不是核心需求
- 记忆内容以「角色设定」和「任务上下文」为主，不需要从对话中自动提取用户偏好
- 团队尚未遇到框架内置 memory/knowledge/rag 子系统的概念混淆问题

具体推荐：CrewAI 的 `role`/`goal`/`backstory` 配合 Task context 链适合角色驱动协作 [ref: facts/crewai-001.md]；LangGraph 的 state channels 配合 checkpoint 适合精确状态流转 [ref: facts/langgraph-001.md]。smolagents 不提供内置持久化 [ref: facts/smolagents-001.md]，OpenHands 的 EventStream 存储执行轨迹而非结构化记忆 [ref: facts/openhands-001.md]——选择二者意味着记忆完全自行解决。

### §6.3 场景二：引入独立记忆层

当框架内置方案触及天花板时，独立记忆层是更可持续的选择。Mem0 和 Letta 不是竞争关系，而是回答不同问题的互补方案。

**选择 Mem0 的信号**：Agent 已用某框架实现，需添加跨 session 持久记忆或多 Agent 共享用户画像；团队已有向量数据库基础设施 [ref: facts/mem0-001.md]。

**选择 Letta 的信号**：Agent 需要「自我认知」和主动记忆管理；上下文窗口的 token 分配必须精确可审计 [ref: facts/letta-001.md]。

### §6.4 场景三：自建记忆系统

两种情况下自建更合理：**记忆语义与业务强耦合**——医疗 HIPAA、金融监管保留期限等合规约束不是通用记忆层的配置选项可以覆盖的；**记忆更新策略与业务逻辑不可分割**——如「用户撤销同意后 30 天内物理删除所有相关记忆」或「记忆更新需第二人审批」，这些策略需要深度嵌入业务工作流。

### §6.5 迁移的隐性成本

无论选择哪种方案，迁移都有三个常被低估的成本。

**概念对齐成本。** CrewAI 的 memory 包含角色 backstory 和对话历史的混合体，Mem0 的记忆是结构化用户偏好片段——这种语义重定义比代码修改更耗时。

**数据迁移成本。** CrewAI 使用 LanceDB/Qdrant 向量格式 [ref: facts/crewai-001.md]，LangGraph checkpoint 使用独立序列化格式 [ref: facts/langgraph-001.md]。历史数据的提取、清洗和重新嵌入是真实工作量。

**运营维护成本。** Mem0 引入新服务（需监控可用性和延迟），Letta 引入平台锁定。原型阶段不明显，生产环境会转化为 on-call 负担。

> **图 6：记忆方案决策树**
>
> 流程图，从顶部「你的 Agent 需要跨 session 记忆吗？」开始分支。第一支「否」→「框架内置方案足够」（LangGraph state / CrewAI context / AutoGen Extensions）。第二支「是」→「Agent 需要自我认知和主动记忆管理吗？」→「是」→ Letta；「否」→「已有框架且需要多 Agent 共享记忆吗？」→「是」→ Mem0；「否」→「记忆语义与业务强耦合或有特殊合规要求吗？」→「是」→ 自建；「否」→ Mem0（通用独立层）。每个叶子节点标注社区规模和 star 数参考。提示词详见 `image-prompts/agent-memory-misconceptions.md` 图 6。

### §6.6 结论

Agent 记忆系统的选择不是「哪个框架记忆功能更强」的横向对比，而是「你的 Agent 需要什么样的记忆」的纵向追问。框架内置方案适合原型和单 session 场景，独立记忆层适合跨 session 和共享记忆场景，自建方案适合强业务耦合和特殊合规场景。理解自己的需求在记忆语义频谱上的位置，比追逐「comprehensive memory support」的营销承诺更重要。
