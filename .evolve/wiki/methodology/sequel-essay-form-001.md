---
name: sequel-essay-form-001
description: 续篇长文的形态识别方法论——在已有知识库基础上扩展新项目的写作框架
tags: ["deep-tech-essay", "sequel-writing", "agent-framework-analysis", "chinese-technical-writing", "cross-project-comparison"]
applies_to: ["续篇深度技术长文", "系列文章第二篇及以后"]
does_not_apply_to: ["首篇从零介绍", "独立单篇不依赖前文", "入门科普"]
evidence_sources:
  - "raw:.evolve/library/methodology/deep-tech-essay-agent-architecture-001.md — 首篇形态方法论"
  - "raw:.evolve/library/methodology/reverse-anthropic-building-effective-agents.md — Anthropic 模式归纳法"
  - "raw:articles/published/five-pole-agent-frameworks.md — 首篇成稿结构实证"
  - "raw:articles/published/smolagents-vs-langgraph.md — 第二篇成稿结构实证"
evidence_type: raw
independent_sources: 3
anti_pattern_count: 3
learned_from: ["首篇五极长文实际写作经验", "Anthropic Building Effective Agents 续篇假设", "中文技术社区系列文常见失败模式观察"]
---

# 续篇深度技术长文的形态识别

## 1. 续篇 vs 首篇的核心差异

| 维度 | 首篇（五极长文） | 续篇（扩展新框架） |
|------|------------------|-------------------|
| 读者前置知识 | 零假设；每个框架从零介绍 | 默认读者已知"五维坐标系"和基础概念 |
| 结构重心 | 建立坐标系 → 逐个填充 → 全景对比 | 引入新维度 → 与已有框架对比 → 升级坐标系 |
| 项目介绍深度 | 每个项目 2000-3000 字完整拆解 | 新项目 1500-2000 字，已有项目仅引用 |
| 对比表功能 | 横向全景对比（16 维） | 纵向差异对比（新增维度 vs 已有） |
| 叙事钩子 | "为什么需要框架" | "首篇没覆盖到的框架怎么处理" |

## 2. 续篇的两种可行结构

### 结构 A："新维度切入"（推荐用于新增项目数 >=3）

以一个新维度（如"软件工程 Agent""可视化编排""企业级 Runtime"）作为主线，将新框架纳入该维度，并与首篇已覆盖框架在该维度上的表现做对比。

- 示例："从聊天到编码：软件工程 Agent 的边界"——OpenHands 为主角，同时对比 smolagents（代码执行极简）和 AutoGen（多 Agent 编码协作）
- 优点：避免重复介绍已有框架，聚焦新维度
- 风险：如果新维度定义不清，会变成"又一个清单"

### 结构 B："坐标系升级"（推荐用于新增项目数 1-2，但维度深刻）

保持首篇的五维坐标系，增加第 6 维（如"持久化语义""沙箱安全""可视化编排"），重新对所有框架（含新加入的）在该维度上排位。

- 示例：增加"工程化成熟度"维度，OpenHands 得高分，smolagents 得低分
- 优点：与首篇形成有机延续，读者有认知连续性
- 风险：需要重新评估已有框架在新维度上的表现，可能推翻首篇结论

### 结构 C："专题深潜"（备选，用于单一项目特别重要时）

选一个特别重要的新项目做深度单项目拆解，只在必要时引用首篇框架做对比。

- 示例："OpenHands 的架构解剖：一个软件工程 Agent 是如何工作的"
- 优点：深度最大，可产出项目专属 facts 和方法论
- 风险：与首篇关联弱，系列感不足

## 3. 行业顶尖续篇样本（识别结果）

**国际标杆**：

- Anthropic 的 "Building Effective Agents" 本身不是续篇，但其内部结构（从 building block → workflow → agent → 何时不该用）呈现的是"认知升级"叙事，可作为续篇节奏参考
- LangChain 的系列文章（从 "What is an agent?" 到 "Agent memory" 到 "Multi-agent"）是典型的维度递进结构，每篇假设读者已读过前文

**中文社区参考**：

- 多数中文技术系列文的问题是"每篇独立成文"，没有真正的续篇结构。反例：某作者写"Redis 系列"共 5 篇，每篇都从零介绍 Redis 是什么
- 正面案例稀缺，这也是本项目的差异化机会

## 4. Ground Truth 形式（续篇特有）

| 断言类型 | 证据形式 | 续篇特殊要求 |
|----------|----------|-------------|
| 新项目状态、star/fork | local-command | 必须与首篇数据同时查询，保证时间一致性 |
| 新项目架构设计 | raw | 需额外关注与首篇已有框架的对比点（如 OpenHands vs smolagents 的代码执行沙箱差异） |
| 跨项目对比（含已有框架） | raw + url | 必须引用首篇 facts 卡，避免重复调研 |
| 首篇结论的引用/修正 | raw | 如推翻首篇结论，必须有显式说明和新证据 |

## 5. 脑内基线 vs 研究 diff

**脑内默认假设（基线）**：
- 续篇 = 首篇 + 更多项目，结构不变
- 新项目介绍深度应与首篇相同
- 已有框架在续篇中不需要再提

**预计反共识点**（待后续 session 验证）：
- 续篇的深度应来自"新维度"而非"更多项目"——5 个项目讲清楚 > 10 个项目讲不清楚
- 已有框架在续篇中需要"被重新提及"，因为读者需要锚点——完全不讲会造成认知断层
- 续篇的对比表应更窄更深（3-4 维×5-6 项目），而非首篇的广覆盖（16 维×5 项目）

## 6. 本轮结论：新文章选题决策

基于当前知识库状态（5 个 facts 已齐备，OpenHands/Dify/Semantic Kernel 缺失）和 Target Essay Series 规划，本轮确定下一篇文章选题：

**选题**："从黑盒到白盒：OpenHands 的软件工程 Agent 架构解剖"（结构 C 专题深潜，但会引用首篇坐标系）

**理由**：
1. OpenHands 是 2024-2025 年软件工程 Agent 领域最受关注的项目之一，有明确的 GitHub 仓库和活跃社区
2. 它与首篇五极中的 smolagents（极简代码执行）和 AutoGen（多 Agent 协作）形成天然对比，但差异维度足够深刻（沙箱安全、工具链集成、评审反馈循环）
3. 专题深潜结构允许我们先产出一份高质量的 OpenHands facts 卡，这是可复用增量
4. Dify 和 Semantic Kernel 属于"平台/企业级 Runtime"维度，更适合作为后续"企业 Agent 平台"专题的主角

**前置条件缺口**：
- OpenHands facts 卡缺失（Step C 任务）
- 与 smolagents/AutoGen 的对比维度 rubric 缺失（可在写 facts 时同步提取）

## Sources
- raw:.evolve/library/methodology/deep-tech-essay-agent-architecture-001.md
- raw:.evolve/library/methodology/reverse-anthropic-building-effective-agents.md
- raw:articles/published/five-pole-agent-frameworks.md
- raw:articles/published/smolagents-vs-langgraph.md
