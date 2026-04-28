---
source: "langchain-what-is-an-agent-20240628.md"
url: "https://blog.langchain.dev/what-is-an-agent/"
authors: ["Harrison Chase"]
date_published: "2024-06-28"
reverse_engineered: "2026-04-28"
---

# 逆向工程：LangChain "What is an AI agent?"

## 1. 宏观结构

| 层级 | 内容 | 占比（估算） |
|------|------|-------------|
| 问题引入 | "我每天都被人问这个问题" | ~3% |
| 定义尝试 + 自我质疑 | 给出技术定义，立即承认不完美 | ~10% |
| 引入光谱概念 | Andrew Ng 的 tweet → 自动驾驶级别类比 | ~8% |
| Agentic 光谱详解 | Router → State Machine → Autonomous Agent | ~20% |
| "为什么需要这个概念" | 概念的工具价值论证 | ~8% |
| 光谱的五个维度 | Build / Run / Interact / Evaluate / Monitor | ~35% |
| "Agentic is new" | 产品化收束：LangGraph + LangSmith | ~16% |

**结构特征**：
- 全文围绕"一个概念（agentic）如何帮助思考"展开，而非"什么是 agent"
- 采用"问题→定义困境→概念升级→工具价值→产品落地"的递进链
- 五个维度（build/run/interact/evaluate/monitor）使用完全平行的句式结构

## 2. 笔法与节奏

### 2.1 用自我质疑建立可信度
开篇给出技术定义后，第二段立即自我反驳："Even here, I'll admit that my definition is not perfect." 这不是修辞，而是**元认知框架**——告诉读者"我在思考如何思考"。

### 2.2 概念升级法（reframing）
核心笔法：不把争论放在"什么是 agent"，而是升级为"什么是 agentic"：
- 原问题：二元争论（是/不是 agent）
- 升级后：光谱连续体（多 agentic）
- 效果：消解争论，转化为设计维度

### 2.3 类比的使用与限制
使用 Andrew Ng 的"自动驾驶级别"类比，但：
- 不是 LangChain 原创，而是引用权威第三方
- 仅用于引入光谱概念，后续立即回归技术定义
- 避免类比过度延伸

### 2.4 平行结构强化论点
五个维度的段落使用几乎相同的句式开头：
- "The more agentic your system is, the more an orchestration framework will help."
- "The more agentic your system is, the harder it is to run."
- "The more agentic your system is, the more you will want to interact with it..."

这种重复不是冗余，而是**认知脚手架**——让读者预期下一段的结构。

### 2.5 产品化收束的诚实性
最后一段引向 LangGraph 和 LangSmith，但：
- 前文已充分论证"为什么需要新工具"
- 产品提及是作为论证的自然结论，而非广告插入
- 没有功能列表，只有"motivated us to build"

## 3. 证据密度与形式

| 断言类型 | 证据形式 | 密度 |
|---------|---------|------|
| 光谱定义 | 类比（自动驾驶）+ 技术描述 | 中等 |
| 五个维度的需求 | 纯逻辑推导，无外部引用 | 每个维度 1 段 |
| 产品动机 | 内部决策叙述（"motivated us"） | 1 段 |
| 客户实践 | 无 | — |

**特征**：
- 几乎不引用外部案例或数据
- 证据形式以逻辑推导和概念分析为主
- 与 Anthropic 形成鲜明对比：Anthropic 用客户案例堆叠，LangChain 用概念清晰度取胜

## 4. 类比处理

| 类比 | 出现位置 | 处理方式 |
|------|---------|---------|
| 自动驾驶级别 | 引入光谱概念 | 引用 Andrew Ng，迅速过渡到技术定义 |
| TED talk 幻灯片 | Agentic 光谱 | 仅提及存在，未展开描述 |
| Voyager paper | Autonomous Agent 级别 | 作为学术引用，增加技术可信度 |

**特征**：类比作为"认知入口"使用，绝不作为论证主体。

## 5. 反共识呈现技法

1. **重新定义问题**：不是"什么是 agent"，而是"agentic 程度如何"——把二元争论变连续谱
2. **框架倡导中的自我限制**：作为框架作者，承认"不是所有系统都需要框架"（"The more agentic your system is, the more an orchestration framework will help" 隐含了"不够 agentic 则不需要"）
3. **概念先于产品**：产品出现在最后，且仅作为概念论证的自然延伸

## 6. 与 Anthropic 的关键差异

| 维度 | Anthropic | LangChain |
|------|-----------|-----------|
| 核心策略 | 案例归纳法 | 概念光谱法 |
| 证据形式 | 客户实践 + 内部实现 | 逻辑推导 + 类比引入 |
| 框架态度 | 怀疑和警告 | 有条件倡导 |
| 反共识强度 | 强（"别用框架"） | 温和（"看程度决定"） |
| 文章功能 | 实践指南 | 概念澄清 + 产品叙事 |
| 附录使用 | 大量深度内容压入附录 | 无附录 |
| 自我质疑 | 在限制和负面中体现 | 在定义不完美中直接体现 |

## 7. 可学技法清单

- [ ] 用自我质疑建立可信度（"我承认这不完美"）
- [ ] 将二元争论升级为连续光谱，消解对立
- [ ] 平行句式结构作为认知脚手架
- [ ] 类比仅作入口，论证主体回归技术精确性
- [ ] 产品提及前置充分论证，使其成为自然结论
- [ ] 概念文章可以不依赖外部案例，靠逻辑推导取胜
