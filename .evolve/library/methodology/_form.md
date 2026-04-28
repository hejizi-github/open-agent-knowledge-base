## 意图锚定（Step 0，自动默认）
- **产物形态**: 研究知识库 + 深度中文技术长文（每篇 10,000+ 字）；本轮先完成输出体裁识别与顶尖样本定位
- **读者定位**: 有经验的后端/AI 工程师、技术负责人、产品负责人；非入门科普
- **与现状关系**: 补齐空白；从零建立 methodology、facts 和 source 层
- **本轮可逆默认假设**: 默认以 Anthropic 式"实践架构分析"为主文风；若用户倾向更偏商业/行业分析，后续可调整
- **需要用户确认但不阻塞本轮的点**: none

---

## 形态识别（Step A）

### 1. 输出体裁

双层输出体系：

- **知识层（Knowledge Layer）**：结构化项目资料卡（project profile）、架构模式（pattern）、评估标准（rubric）、来源索引（source index）。形态对标：技术调研笔记 + 架构文档 + 竞品分析表的混合。
- **文章层（Essay Layer）**：面向中文读者的深度技术长文，单篇 10,000+ 中文字。必须包含：
  - 问题背景与动机
  - 项目拆解（≥1 个核心开源项目）
  - 架构图说明（用生图提示词替代直接插图）
  - 对比表（跨项目时 ≥3 个）
  - 设计取舍与失败模式
  - 实践建议
  - 引用来源
  - 图片生成提示词（用途、构图、关键元素、风格、比例、避免项）

体裁定位：**技术架构深度分析 + 开源项目调研报告 + 长篇技术散文的混合体**。非新闻、非论文、非教程。核心特征是"工程师写给工程师的决策参考"。

### 2. 行业顶尖执行者

按子体裁细分：

**A. Agent 架构实践写作（国际标杆）**

| 作者/团队 | 代表作 | 核心特点 | 可学之处 |
|-----------|--------|----------|----------|
| Anthropic Research Engineering (Erik S., Barry Zhang) | [Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) (Dec 2024) | 从客户实践归纳模式；分层复杂度（building block → workflow → agent）；Appendix 深入工具设计；反框架倾向 | 模式归纳法、复杂度分层、"反共识"呈现（简单 > 复杂） |
| Harrison Chase / LangChain | [What is an AI agent?](https://blog.langchain.dev/what-is-an-agent/) (Jun 2024) | 光谱式定义（agentic spectrum）；技术概念产品化；框架演进叙事；TED talk 转化 | 概念光谱法、技术-产品-生态三层叙事 |
| Simon Willison | simonwillison.net 系列文章 | MWE 驱动；命令行可复现；极致简洁；个人实验记录 | 可复现性、最小示例、诚实记录失败 |

**B. 中文深度技术长文（对标对象）**

- **InfoQ 架构头条 / 阿里技术 / 腾讯云开发者社区深度专栏**
  - 特点：万字起步、架构图 + 流程图、源码级拆解、业务场景落地
  - 局限：有时过于面向大厂内部场景，开源项目通用性不够
- **稀土掘金高赞长文（特定作者）**
  - 特点：代码示例丰富、结构扁平、情感化叙事较弱
  - 局限：证据密度不足、缺少跨项目对比

**C. 咨询/研究级项目分析**

- A16Z AI research essays — 行业趋势 + 技术架构混合，但技术深度不足
- Papers with Code survey papers — 学术严谨但可读性差，不适合直接对标

**结论**：本项目文章层的**首要对标**是 Anthropic 的 "Building Effective Agents"（模式归纳、反共识、实践导向），**次要对标**是 Harrison Chase 的"光谱式定义"（概念清晰度）。中文表达层参考 InfoQ 架构头条的万字长文节奏，但要补充其跨项目对比和失败模式分析。

### 3. Ground Truth 形式

| 断言类型 | 证据形式 | 最低要求 |
|----------|----------|----------|
| 项目状态、star/fork、license、维护活跃度 | `local-command`（curl/gh CLI 查询） | 命令 + 输出 + 时间戳 |
| 架构设计、API 签名、代码示例 | `raw`（官方文档、源码） | 保存到 `.evolve/raw/repos/` 或 `.evolve/raw/web/` |
| 跨项目对比结论 | `url` ≥ 2 独立来源 | 交叉验证，禁止单来源断言 |
| 行业趋势、市场份额 | `url` + 时效标注 | 必须标注数据时间点 |
| 工具/框架使用建议 | `local-command`（MWE 可运行） | 保留可复现代码片段 |

### 4. 顶尖样本的共性特征（跨样本归纳）

分析 Anthropic + LangChain + Simon Willison 的样本后，归纳出以下共性：

1. **分层复杂度**：都从最简单的 building block 开始，逐步叠加，而非一开始就抛出完整架构。
2. **模式命名 + 明确边界**：每个模式都有名字（Prompt Chaining, Routing, Parallelization...），并明确回答 "When to use / When NOT to use"。
3. **反共识作为论点**：Anthropic 的核心论点是"简单模式比复杂框架更有效"；LangChain 的核心论点是"不要争论什么是 agent，要看 agentic 程度"。
4. **实践锚点**：每个抽象概念都对应客户案例或内部实现（SWE-bench, computer use, customer support）。
5. **工具/接口设计被提升到与架构同等重要**：Anthropic 的 Appendix 2 专门讲 tool prompt engineering；LangChain 强调 orchestration framework 的抽象质量。
6. **自我限定的诚实性**：都明确说了"什么时候不该用"（Anthropic: "might mean not building agentic systems at all"）。

### 5. 脑内基线与反共识点预览（供 Step B 展开）

**脑内默认假设（基线）**：
- 深度长文 = 大而全的综述，覆盖越多越好
- 架构图 = 画得越详细越好
- 图片 = 直接生成或截图
- 中文技术写作 = 翻译英文优质内容 + 加代码示例

**预计反共识点**（待 Step B 验证）：
- Anthropic 的"简单 > 复杂" vs 中文读者的"框架崇拜"（国内更易接受 CrewAI/AutoGen 等封装框架）
- "不写 listicle" vs 国内技术社区高赞内容多为清单体
- "图片只给提示词" vs 国内读者习惯直接看图
- "失败模式"章节在国内技术长文中极为罕见，但 Anthropic 将其作为核心卖点

---

*形态识别完成。下一步建议进入 Step B：对上述顶尖样本进行逐份逆向工程，产出可复用的写作方法论条目。*
