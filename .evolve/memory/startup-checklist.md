# Session Startup Checklist

每次 session 开始时按顺序执行，不凭记忆拼接路径。

## 1. 路径常量（物理记录，禁止脑内硬编码）

| 常量名 | 绝对路径 | 说明 |
|--------|----------|------|
| `EVOLVE_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve` | 经验库根目录 |
| `WIKI_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve/wiki` | Wiki 语义目录 |
| `RAW_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve/raw` | 不可变证据源 |
| `LIBRARY_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve/library` | Legacy 兼容镜像 |
| `SESSIONS_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve/sessions` | Session 控制面 |
| `ARTICLES_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/articles` | 长文产物 |
| `MEMORY_DIR` | `/Users/yuanshicheng/workspace/self-evolve-projects/open-agent-knowledge-base/.evolve/memory` | 持久记忆 |

## 2. Session 启动必做（顺序不可跳）

1. [ ] 读取 `next.md` 确认上轮建议的下一步
2. [ ] 读取 `_form.md` 检查意图锚定是否过期（>1 轮未更新则刷新）
3. [ ] 读取 LLM Wiki Index（全局 + 项目）判断可用 expert/pattern/rubric
4. [ ] 检查 Source Inbox（`raw/source-pack/`、`raw/web/`）是否有预置来源
5. [ ] 确认六极 facts 齐备状态（`wiki/facts/*.md` 数量 = 6）
6. [ ] 确认已发表文章列表（`articles/index.md`）

## 3. 控制面文件创建/更新（动手前必须先有）

1. [ ] `task_framing.md`：Goal / Wiki Pages Used / Expert Lens / Default Assumptions / This Session Step
2. [ ] `step.json`：session / selected_step / why_this_step / preconditions / outputs / evidence / next_step
3. [ ] 如缺失，用 Write 创建（不要假设上一轮已正确写入）

## 4. Wiki-first 决策检查

- Wiki 方法论层是否覆盖当前标签？否 → 选 Step B
- Wiki 事实层是否覆盖产物关键断言？否 → 选 Step C
- 脑内基线是否已归档？否 → 先写 brain_baseline
- 是否存在 Orchestrator Directive？是 → 必须优先产出用户产物变化（Step D/E）

## 5. 效率承诺（上轮经验）

- 需要完全一致的 wiki/library 镜像文件：用 `cp` 批量同步，禁止逐行 Edit
- Step C 事实验证 session 控制在 25 turns 内，超出时审视是否有过度验证
- 不要在一个 session 里同时跑多个 Step
