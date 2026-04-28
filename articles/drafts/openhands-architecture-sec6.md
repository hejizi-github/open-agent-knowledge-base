## §6 实践建议：何时选择 OpenHands（~1,000 字）

§5 把 OpenHands 放入了升级后的六维坐标系，但坐标系本身不是决策工具。对于需要在周一早上向技术评审会汇报选型结论的工程师，需要的是一套可操作的判断规则。§6 提供这套规则——不是"OpenHands 好 vs 不好"的二元判断，而是"你的场景匹配 OpenHands 的架构假设吗"的结构性分析。

### §6.1 适用场景

**场景一：Agent 需要在隔离环境中执行真实代码。** 这是 OpenHands 最核心的架构假设，也是选型决策的"根节点"。如果你的场景涉及修改代码库、运行测试套件、执行构建命令、操作浏览器自动化——即任何需要与真实文件系统和进程交互的任务——OpenHands 的 Runtime-Sandbox 架构提供了六项目中最完整的执行深度 [ref: wiki/facts/openhands-001.md]。SWE-bench 的 77.6 分 [ref: raw:openhands-readme.md] 是这个假设在基准测试中的验证，但生产环境中的验证同样重要：你的团队是否需要一个能在 Docker 容器中安全运行 `rm -rf`、`pip install`、`pytest` 的 Agent？

**场景二：团队需要多种交互模式的渐进式采用。** OpenHands 的五层产品矩阵 [ref: wiki/facts/openhands-001.md] 支持从 SDK（框架集成）到 CLI（个人终端）到 GUI（团队演示）到 Cloud/Enterprise（组织部署）的渐进路径。

这个路径的价值不在于"选项多"，而在于"迁移成本低"——同一个 Agent 配置可以从本地 CLI 测试无缝切换到 Cloud 生产环境，因为底层共享 software-agent-sdk [ref: wiki/facts/openhands-001.md]。

**场景三：组织需要平衡开发效率与生产隔离。** Runtime 的可插拔设计（Docker Sandbox vs local）使 OpenHands 能同时满足两种矛盾需求：开发阶段用 `RUNTIME=local` 快速迭代（启动时间数秒），生产阶段切换到 Docker Sandbox 保证隔离 [ref: raw:openhands-agents.md]。六项目中，只有 OpenHands 和 smolagents 提供这种双模式，但 smolagents 的 local 执行器明确声明"不是安全沙箱" [ref: wiki/facts/smolagents-001.md]，而 OpenHands 的 local 模式虽也有安全妥协，但至少提供了 Docker 模式作为生产默认。

**场景四：SWE-bench 类任务——代码库理解、bug 修复、功能实现。** OpenHands 在 SWE-bench 上的高分不是偶然的。它的架构设计（EventStream 可恢复 + Runtime 可插拔 + 多模型支持）恰好匹配这类任务的需求：长时间运行、可能失败、需要反复尝试、需要在隔离环境中验证。如果你的团队正在构建类似的"AI 软件工程师"产品，OpenHands 的架构模式比通用 Agent 框架更具参考价值。

### §6.2 不适用场景

**场景一：只需要简单工具调用（搜索、查询、API 调用）。** 如果你的 Agent 任务不涉及代码执行，OpenHands 的 Docker 依赖和 Runtime 抽象会变成不必要的负担。smolagents 的 26,939 star [ref: wiki/facts/smolagents-001.md] 和极简 API 更适合这种场景——它的 CodeAgent 虽然能执行 Python 代码，但核心定位仍是"工具调用框架"，部署复杂度远低于需要 Docker 的 OpenHands。

**场景二：需要精确控制流定义。** 如果你的工作流需要开发者精确控制每一步的状态转换（如审批流程、合规检查点、条件分支），LangGraph 的显式状态图 [ref: wiki/facts/langgraph-001.md] 比 OpenHands 的"半显式"循环更合适。OpenHands 的 AgentController 不暴露细粒度的状态转换接口——它信任 LLM 在每一步的决策，只在循环层面提供结构。这种设计在开放-ended 的代码工程任务中是优势，在严格约束的业务流程中可能是劣势。

**场景三：完全零商业锁定的需求。** OpenHands 的核心代码是 MIT License，但 Enterprise 层是 source-available [ref: wiki/facts/openhands-001.md]，需要商业许可才能长期运行。如果你的组织对 License 有零容忍要求（如某些开源基金会项目或政府机构），需要评估 Enterprise 层的边界。相比之下，smolagents（Apache-2.0）、LangGraph（MIT）、CrewAI（MIT）的全栈 License 更宽松 [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/langgraph-001.md] [ref: wiki/facts/crewai-001.md]。

**场景四：Python < 3.12 的运行环境。** OpenHands 要求 Python >=3.12, <3.14 [ref: wiki/facts/openhands-001.md]。这个限制排除了一些遗留环境（如基于 Python 3.10 的企业内部平台）。五极中的 smolagents 和 CrewAI 对 Python 版本的要求更宽松 [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/crewai-001.md]，在旧环境部署时兼容性更好。

### §6.3 决策树

将上述分析转化为一个可直接用于技术评审的决策流程：

```
需要 Agent 执行真实代码（修改文件系统、运行测试、操作浏览器）？
  ├─ 否 → 考虑 smolagents（轻量工具调用）或 LangGraph（精确控制流）
  └─ 是 → 需要多种交互模式（CLI + GUI + SDK）的渐进部署？
           ├─ 否 → 需要精确控制每一步的状态转换？
           │        ├─ 是 → 考虑 LangGraph（显式状态图）
           │        └─ 否 → OpenHands SDK 或 AutoGen（但 AutoGen 已进入维护模式）
           └─ 是 → 需要企业级自托管（VPC、RBAC、协作）？
                    ├─ 否 → OpenHands Local GUI 或 Cloud
                    └─ 是 → 评估 Enterprise 层 source-available License 可接受？
                             ├─ 否 → 考虑 CrewAI Cloud 或自建 LangGraph + LangSmith
                             └─ 是 → OpenHands Enterprise
```

这个决策树的根节点不是"哪个框架 star 多"，而是"你的场景需要代码执行深度吗"。这个根节点的选择来自 §5.3 提出的"代码执行深度"维度——它在 2026 年的 Agent 框架选型中，比"模型支持数量"或"社区活跃度"更能区分框架的本质差异。大多数框架对比文章将"支持多少种 LLM"作为首要比较维度，但在 2026 年这个维度已经趋同：OpenHands、smolagents、CrewAI、LangGraph 都通过 LiteLLM 或自研适配层支持 Claude、GPT、Gemini、Qwen 等主流模型 [ref: wiki/facts/openhands-001.md] [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/crewai-001.md] [ref: wiki/facts/langgraph-001.md]。选型决策不应基于已经趋同的维度，而应基于框架的架构假设是否与你的场景匹配。

如果你读到这里，仍然不确定 OpenHands 是否适合你的团队，有一个简单的验证方法：用 Docker 启动 OpenHands 的 Local GUI，给一个真实的代码库任务（如"修复这个仓库中的某个已知 bug"），观察三个指标：Agent 能否在 Sandbox 中成功运行测试？失败时能否从 EventStream 中恢复？前端能否在 Runtime 重启后继续显示历史事件？这三个指标的通过与否，比任何 star 数或 benchmark 分数都更能说明 OpenHands 是否适合你的场景。
