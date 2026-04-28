---
source: "anthropic-building-effective-agents-20241219.md"
url: "https://www.anthropic.com/research/building-effective-agents"
authors: ["Erik S.", "Barry Zhang"]
date_published: "2024-12-19"
reverse_engineered: "2026-04-28"
---

# 逆向工程：Anthropic "Building Effective Agents"

## 1. 宏观结构

| 层级 | 内容 | 占比（估算） |
|------|------|-------------|
| 开头钩子 | "最成功实现使用简单可组合模式，而非复杂框架" | ~2% |
| 定义与边界 | Agent vs Workflow 的精确区分 | ~8% |
| 使用时机判断 | "何时用 / 何时不用 / 何时甚至不该建 agent" | ~10% |
| 框架态度 | 承认框架价值但明确警告抽象层危害 | ~8% |
| 核心模式 | 5 种 Workflow + 1 种 Agent，从简单到复杂递进 | ~35% |
| 组合原则 | "非规定性，测量性能后迭代" | ~5% |
| 总结 + 三原则 | 极简收尾 | ~5% |
| 附录1：实践案例 | Customer support + Coding agents（客户案例 + 内部实现） | ~15% |
| 附录2：工具工程 | 工具设计被提升到与架构同等重要 | ~12% |

**结构特征**：
- 正文部分极其克制（~65%），大量深度内容被压入附录
- 采用"先给全貌，再给深度"的两层结构
- 每个 Workflow 使用完全一致的子结构：定义 → 使用时机 → 示例

## 2. 笔法与节奏

### 2.1 反共识作为开头钩子
开篇第一句即抛出反直觉结论："最成功的实现并非使用复杂框架"。这不是渐进式论证，而是先放结论、再展开证据。

### 2.2 "When to use / When NOT to use" 双栏结构
每个模式段落都包含两个判断：
- "When to use this workflow: ..."
- 隐含的是 "When NOT to use"——通过对比其他模式间接表达

在 Agent 段落中，甚至直接写了负面："The autonomous nature of agents means higher costs, and the potential for compounding errors."

### 2.3 实践锚点密度
每个抽象概念都对应具体案例：
- Prompt chaining → 营销文案翻译、文档大纲
- Routing → 客服分类、模型路由（Haiku vs Sonnet）
- Parallelization → 内容审核、代码漏洞审查
- Orchestrator-workers → SWE-bench 多文件编辑
- Evaluator-optimizer → 文学翻译、复杂搜索
- Agent → SWE-bench、computer use

**密度**：每个模式 ≥2 个具体示例，且示例横跨不同行业（营销、客服、安全、开发）。

### 2.4 自我限定与诚实性
多处明确说"不该做"：
- "This might mean not building agentic systems at all."
- "optimizing single LLM calls ... is usually enough"
- "don't hesitate to reduce abstraction layers"
- 附录 B 明确说 "we actually spent more time optimizing our tools than the overall prompt"

这不是谦虚修辞，而是**可信度构建策略**——通过主动暴露限制来增强读者信任。

### 2.5 分层复杂度叙事
从 Augmented LLM → Prompt Chaining → Routing → Parallelization → Orchestrator-workers → Evaluator-optimizer → Agents，复杂度严格递增。
每个新增层都明确说明"与前一层的关键区别是什么"。

## 3. 证据密度与形式

| 断言类型 | 证据形式 | 密度 |
|---------|---------|------|
| 模式有效性 | 客户实践 + 内部实现 | 每个模式 ≥2 例 |
| 框架警告 | 直接建议 + 反面假设 | 1 段 |
| 工具设计建议 | 具体反例（相对路径问题）+ 解决方案 | 附录2 整节 |
| 性能/成本权衡 | 定性描述（latency/cost vs performance） | 多次出现，无具体数字 |

**特征**：几乎不使用定量数据（无 benchmark 数字、无成功率百分比），全靠定性案例堆积可信度。

## 4. 类比处理

| 类比 | 出现位置 | 处理方式 |
|------|---------|---------|
| 自动驾驶级别 | 未使用 | — |
| HCI → ACI | 附录2 | 不是简单类比，而是升级为独立概念 "agent-computer interface" |
| 迭代写作过程 | Evaluator-optimizer | "analogous to the iterative writing process a human writer might go through" — 极短，仅一句 |

**特征**：极少使用大众类比；当使用时，目的是精确说明而非降低认知门槛。

## 5. 反共识呈现技法

1. **标题级反共识**：开头即挑战"agent = 复杂自主系统"的直觉
2. **框架怀疑论**：作为 LLM 提供商，却明确警告"不要过度使用框架"——这是利益冲突点的坦诚处理
3. **简单 > 复杂**：全文的隐藏主线是"加法不如减法"，但从不直接说"简单更好"，而是通过案例对比让读者自己得出
4. **工具工程 > 提示工程**：附录2 的核心反直觉结论是"我们在工具上花的时间比提示更多"

## 6. 可学技法清单

- [ ] 开头用反直觉结论做钩子，而非背景铺垫
- [ ] 每个抽象模式配套 "When to use" 判断框架
- [ ] 主动暴露限制和负面，构建可信度
- [ ] 案例横跨不同行业，避免单一场景偏见
- [ ] 深度内容压入附录，保持正文流畅
- [ ] 复杂度严格分层，每层明确与前层的差异
- [ ] 不依赖定量数据，用定性案例堆叠可信度
