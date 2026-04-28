**适用场景**: 文章已通过 Step D lint（draft 字数达标、ref 链路完整、兜底词扫描通过），需要从 `articles/drafts/` 推进到 `articles/published/`。

**步骤**:
1. Read draft 文件确认最终字数与结构；Glob `image-prompts/<slug>.md` 确认提示词包就绪
2. Bash `wc -c` 统计 draft 字节数作为 baseline；Bash `mkdir -p articles/published`
3. Bash `cp` 复制 draft 到 published；Read published 文件首行确认复制成功
4. Edit 在文件最顶部插入 YAML frontmatter，schema：title / slug / date / word_count / tags / description / source_refs / image_prompts / license
5. Grep `> \*\*图 N` 拿到当前所有占位符位置；对照 image-prompts 包确认每张图应在哪个章节边界
6. 批量 Edit：删除位置错配的旧占位符 + 在正确章节边界插入新占位符 + 统一占位符格式（建议格式：`> **图 N：标题**`+ 一行说明）
7. Edit 在文末追加图片使用清单（图 1-6 + 封面图 7），交付给设计/插画环节
8. Read 一次 published 文件全文，肉眼校验 frontmatter / 占位符 / 清单一致；Bash `wc -c` 与 `grep -c "图.*插入位置\|> \*\*图"` 验证
9. Edit articles/index.md 把新文章加入 Published 列表
10. Write step.json 时 outputs 必须包含：published 文件、articles/index.md、image-prompts/<slug>.md、4 个控制面文件

**注意事项**:
- frontmatter 的 source_refs 字段应列出文章引用的所有 facts/methodology 文件名，便于读者溯源
- 图片占位符的章节归属容易错配——配图说明的"主题"决定章节，不是占位符在 outline 中的位置；迁移前用 outline 的图片定位说明做交叉验证
- 不要在 Step E 修改文章论点、证据或结构，只做格式增强；任何论点修改必须回退到 Step D
- step.json outputs 容易遗漏 articles/index.md，规划阶段就要识别"出版即维护索引"
- evidence type 与 ref 格式严格对应：local-command/raw 配文件路径，url 配 http(s) 链接
