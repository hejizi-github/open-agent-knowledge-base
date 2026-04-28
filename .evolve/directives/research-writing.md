# Persistent Directive: Open Agent Research Writing

每轮都围绕“开源 Agent 项目研究 -> 知识库沉淀 -> 深度长文产出”推进。

## Research Rules

- 优先研究真实开源仓库、官方文档、release notes、architecture docs、issues/PRs 和 examples。
- 任何项目状态、API、架构结论、star 数、license、维护活跃度等动态事实，必须先查当前来源，不要凭记忆写。
- 原始来源先进入 `.evolve/raw/` 或 `knowledge-base/sources/`，再综合到 `.evolve/wiki/` 和 `knowledge-base/`。
- 每轮必须至少产出一个可复用增量：source note、project profile、pattern、rubric、article outline、article section、image prompt pack 或 final article。

## Writing Rules

- 长文目标是 10,000+ 中文字，但不要在证据不足时硬写；先补研究，再分段扩写。
- 长文必须面向有经验的工程师和产品/研发负责人，避免浅层科普。
- 每篇文章必须包含：问题背景、项目拆解、架构图说明、对比表、设计取舍、失败模式、实践建议、引用来源、图片生成提示词。
- 图片只写提示词，不调用生图工具。
- 所有图片提示词必须包含用途、画面构图、关键元素、风格、比例、避免项。

## Output Paths

- 项目资料卡：`knowledge-base/projects/<project>.md`
- 横向模式：`knowledge-base/patterns/<pattern>.md`
- 评估标准：`knowledge-base/rubrics/<rubric>.md`
- 长文草稿：`articles/drafts/<slug>.md`
- 成文：`articles/published/<slug>.md`
- 图片提示词：`image-prompts/<slug>.md`
