**适用场景**: 执行 Step A（形态识别）时，需要完成意图锚定、体裁分析、结构模板和选题决策

**步骤**:
1. 读取 library 现有状态（facts、methodology、已发表文章）
2. 读取上一轮 step.json 和 next.md，确认当前知识库缺口
3. 检查 wiki 语义目录结构，缺失则创建
4. 更新 `_form.md` 意图锚定（首篇/续篇/系列模式切换）
5. 编写形态识别方法论文件（差异矩阵、可行结构、顶尖样本、选题决策）
6. 并行写入控制面文件（task_framing.md、step.json、wiki_update.md、next.md）
7. 同步镜像 wiki → library（兼容旧循环）
8. 验证所有输出文件存在，JSON 文件用 `python3 -m json.tool` 做语法校验

**注意事项**:
- step.json 中 why_this_step 字段若含中文引号，必须用直角引号「」替代 ASCII 弯引号，或做 JSON 转义
- 控制面文件写入后必须立即做 JSON 语法验证，不能留到 review 阶段
- 续篇形态识别的核心产出是"差异矩阵 + 结构模板 + 选题决策"，不是项目调研
