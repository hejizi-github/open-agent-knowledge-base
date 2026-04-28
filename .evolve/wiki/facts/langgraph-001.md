---
name: langgraph project profile 001
description: LangChain LangGraph 仓库当前状态、核心架构与关键设计取舍（截至 2026-04-28）
type: project
---

# LangGraph — Project Fact Sheet

## 仓库基础状态

| 字段 | 值 | 来源 |
|------|-----|------|
| 组织 | LangChain AI (@langchain-ai) | GitHub API |
| 仓库 | langchain-ai/langgraph | GitHub API |
| Stars | 30,593 | GitHub API (2026-04-28) |
| Forks | 5,228 | GitHub API (2026-04-28) |
| 创建时间 | 2023-08-09 | GitHub API |
| 最近推送 | 2026-04-28 | GitHub API |
| License | MIT | GitHub API |
| 主语言 | Python | GitHub API |
| Open Issues | 512 | GitHub API |
| 最新 Release | langgraph==1.1.10 (2026-04-27) | GitHub API |
| 生态子包 | prebuilt==1.0.12, checkpoint==4.0.3, cli==0.4.24 | GitHub API |

**Evidence Sources**:
- type=local-command, ref=`curl -sL https://api.github.com/repos/langchain-ai/langgraph`, claim=仓库基础元数据
- type=local-command, ref=`curl -sL https://api.github.com/repos/langchain-ai/langgraph/releases?per_page=5`, claim=Release 历史（含子包独立发布）
- type=raw, ref=`.evolve/raw/github-api/20260428-103651/langgraph_repo.json`
- type=raw, ref=`.evolve/raw/github-api/20260428-103651/langgraph_releases.json`

**时间戳**: 2026-04-28T10:39:00+08:00
**过期条件**: Release 数变化 > 2 个 patch 版本或 star 数变化 > 10%
**置信度**: 高
**独立信源数**: 1（GitHub API 为权威源）

---

## 核心架构声明

### 1. Pregel-inspired 状态机图

LangGraph 的底层执行引擎名为 **Pregel**（直接引用 Google 的 Pregel 图计算框架），代码位于 `libs/langgraph/langgraph/pregel/` 目录：

| 模块 | 职责 |
|------|------|
| `_algo.py` | 图遍历与调度算法 |
| `_loop.py` | 主执行循环 |
| `_runner.py` | 节点运行器（并发/串行） |
| `_checkpoint.py` | 状态持久化与恢复 |
| `_io.py` / `_read.py` / `_write.py` | 状态通道 I/O |
| `_retry.py` | 重试策略 |
| `_executor.py` | 执行器抽象 |

**关键洞察**：LangGraph 不是"agent 框架"，而是"状态机编排框架"。agent 只是其上的一个应用形态。这与 LangChain 博客中 "agentic spectrum" 的定义一致——LangGraph 提供的是显式控制流层，让开发者精确决定 state 如何流转。

**Evidence Sources**:
- type=local-command, ref=`curl -sL https://api.github.com/repos/langchain-ai/langgraph/git/trees/main?recursive=1 | jq`, claim=pregel/ 目录结构
- type=raw, ref=README.md §"Acknowledgements"（明确声明灵感来自 Pregel 和 Apache Beam）

### 2. 状态持久化（Durable Execution）

LangGraph 的核心差异化特性是**将状态机执行持久化到存储后端**：

- **Checkpointing**: 每个步骤完成后自动保存状态快照，失败后可从任意 checkpoint 恢复
- **Short-term memory**: 单 session 内的 working memory（state channels）
- **Long-term memory**: 跨 session 的持久记忆（通过 `langgraph-checkpoint` 子包实现）
- **Human-in-the-loop**: 通过 `interrupt` 机制在任意节点暂停执行，等待人工输入后再继续

**Evidence**: README §"Why use LangGraph?" + release notes 中 checkpoint==4.0.3 的独立发布

---

## 生态位与商业闭环

### 产品矩阵

| 产品 | 角色 | 与 LangGraph 关系 |
|------|------|-------------------|
| **LangGraph** | 低级编排框架（本仓库） | 核心 |
| **LangChain** | 组件库与集成层 | 上游依赖/可选搭档 |
| **LangSmith** | 可观测性、评估、调试 | 下游搭档 |
| **LangSmith Deployment** | 生产部署平台 | 商业化出口 |
| **LangSmith Studio** | 可视化原型设计 | 降低上手门槛 |
| **Deep Agents** *(new)* | 高级 agent 模板（planning + subagents + filesystem） | 高级应用层 |

**关键观察**：LangGraph 作为开源框架是 MIT 许可，但其完整的生产闭环（部署、监控、团队协作）锁定在 LangSmith 商业平台。这是典型的"开源核心 + 商业服务"模式。

**Evidence**: README §"LangGraph ecosystem"

---

## 维护活跃度评估

| 指标 | 值 | 评估 |
|------|-----|------|
| 仓库年龄 | ~1 年 8 个月 | 相对成熟 |
| 最新 commit | 2026-04-28（当天） | 极高活跃度 |
| 最新 release | 2026-04-27（1.1.10） | 几乎每日发布 |
| Open issues | 512 | 与 smolagents 接近，但维护团队更大 |
| Release 频率 | 子包独立发布（prebuilt/checkpoint/cli/langgraph 各自有版本号） | 微服务化发布策略 |
| 仓库体积 | 517,923 KB (~517 MB) | 显著大于 smolagents (7,287 KB) |

**发布策略洞察**：LangGraph 采用 monorepo + 多包独立版本策略。`langgraph` 核心、`langgraph-prebuilt`（预置节点）、`langgraph-checkpoint`（持久化）、`langgraph-cli`（命令行）各自独立发版。这反映了框架复杂度高、模块化程度深。

**Evidence Sources**:
- type=local-command, ref=`curl -sL https://api.github.com/repos/langchain-ai/langgraph/commits?per_page=5`, claim=最近 commit 时间戳
- type=raw, ref=`.evolve/raw/github-api/20260428-103651/langgraph_commits.json`

---

## 与 LangChain 光谱论的映射关系

根据 LangChain "What is an AI agent?" 的光谱定义，LangGraph 处于光谱的**"显式控制流"极端**：

| 光谱维度 | LangGraph 立场 |
|----------|----------------|
| **控制流** | 显式图结构（开发者定义 nodes/edges），非 LLM 动态决定 |
| **工具调用** | 通过 `ToolNode` 显式挂载，LangChain 标准兼容 |
| **人机交互** | 原生 `interrupt` + `Command` 机制，人可在任意节点介入 |
| **记忆** | 结构化 state channels + 可选 checkpoint 持久化 |
| **环境交互** | 通过节点函数任意扩展，框架不限制 |

这与 smolagents 的"黑盒 ReAct loop"形成鲜明对比：LangGraph 要求开发者显式画出状态流转图，smolagents 则把 loop 封装在 agents.py 内部。

---

## 对比表：smolagents vs LangGraph

| 维度 | smolagents | LangGraph |
|------|-----------|-----------|
| **Stars** | 26,939 | 30,593 |
| **创建时间** | 2024-12（5 个月） | 2023-08（1 年 8 个月） |
| **仓库体积** | 7.3 MB | 518 MB |
| **核心代码** | ~1,800 行 agents.py | pregel/ + graph/ 多模块，数万行 |
| **设计哲学** | 极简、代码即 action、黑盒 ReAct | 显式状态机、图即控制流、白盒编排 |
| **Agent 模式** | CodeAgent / ToolCallingAgent | 任意 graph + prebuilt agents |
| **持久化** | 无内置 | 原生 checkpointing + memory |
| **人机交互** | 无内置 | 原生 interrupt |
| **安全沙箱** | E2B/Modal/Docker/WASM（外置） | 框架层不处理，依赖部署环境 |
| **模型支持** | 极广泛（任何 LLM） | LangChain 生态覆盖 |
| **工具支持** | MCP + LangChain + Hub | LangChain 原生 + 任意函数 |
| **发布策略** | 单包版本 | monorepo 多包独立版本 |
| **商业闭环** | 无（HF 生态免费） | LangSmith 商业平台 |

**Evidence Sources**:
- 本表所有数据来自上述两个 facts 文件中的 local-command evidence
- 设计哲学对比来自 README 文本分析（非脑内推断）

---

## 已知限制与失败模式

1. **学习曲线陡峭**：LangGraph 要求开发者理解图论概念（nodes, edges, state channels, Pregel 执行模型），上手门槛明显高于 smolagents 的 "`agent.run()`" 风格。
2. **过度工程化风险**：对于简单的单步 tool-call 任务，LangGraph 的图抽象可能是杀鸡用牛刀——与 Anthropic "简单 > 复杂"的警告直接冲突。
3. **版本碎片化**：monorepo 多包独立版本导致依赖管理复杂（需确保 langgraph + prebuilt + checkpoint 版本兼容）。
4. **与 LangChain 的耦合争议**：虽然 README 声明 "can be used without LangChain"，但生态文档、示例和预置组件大量依赖 LangChain，实际独立使用成本不低。
5. **商业锁定倾向**：完整可观测性和部署能力绑定 LangSmith，开源部分仅提供运行时。
