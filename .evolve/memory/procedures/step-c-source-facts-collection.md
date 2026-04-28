**适用场景**: 执行 Step C 时需要从零收集一个开源项目的源码级 facts 卡（包结构、核心类、API 设计、issues 实证）

**步骤**:
1. 检查 gh CLI 认证状态；未认证则标记「优先用 raw.githubusercontent.com」
2. 通过 GitHub REST API 或 raw GitHub 获取仓库根目录结构，保存为 raw source
3. 定位主包目录（名称通常与仓库同名），获取包内子模块列表
4. 获取 pyproject.toml / package.json 提取依赖、版本、描述、可选后端列表
5. 获取 __init__.py 提取公开 API 导出类型
6. 获取核心源码文件（如 memory/main.py, schemas/*.py），保存完整文件到 raw/
7. 用 python3 脚本分析源码结构（提取类定义、方法签名、行数），不用 grep -P
8. 通过 REST API 获取最近 issues，用 python3 过滤与主题相关的 issues；防御 null body/title 字段
9. 将分析结果按 facts 卡 schema 写入 wiki/facts/，并镜像到 library/facts/

**注意事项**:
- 所有 curl 获取的文件必须 `wc -c` 验证非空，0 字节视为失败并重新定位路径
- issues 过滤脚本对 null 字段用 `or ''` 防御，不假设字段一定存在
- gh 未认证时 REST API 调用量控制在 3 次以内（repo 元数据 + issues），其余走 raw GitHub
- 获取源码前先用包结构确认文件存在，不凭记忆构造路径
