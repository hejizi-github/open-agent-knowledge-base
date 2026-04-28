---
domain: agent-memory
conclusion: "Letta（原 MemGPT）将记忆从存储后端提升为核心架构抽象，通过 Block（上下文窗口保留区）和 OS 式记忆分层（Core/Archival/Recall）实现有状态 Agent 的长期记忆与自我改进。"
evidence_sources:
  - "raw:.evolve/raw/letta-repo-api.json"
  - "raw:.evolve/raw/letta-readme.md"
  - "raw:.evolve/raw/letta-pyproject.toml"
  - "raw:.evolve/raw/letta-init.py"
  - "raw:.evolve/raw/letta-schemas-memory.py"
  - "raw:.evolve/raw/letta-schemas-block.py"
  - "raw:.evolve/raw/letta-issues-recent.json"
  - "raw:.evolve/raw/memgpt-paper-abstract.html"
  - "raw:.evolve/raw/memgpt-arxiv-search.xml"
evidence_type: raw
timestamp: "2026-04-28T12:00:00Z"
expires: "2026-07-28T12:00:00Z"
confidence: high
independent_sources: 9
---

# Letta — 项目事实卡

## 1. 项目元数据

| 字段 | 值 | 来源 |
|------|-----|------|
| 全名 | letta-ai/letta | repo API |
| 曾用名 | MemGPT（2023-2024） | README 标题 + arXiv 论文 |
| Stars | 22,348 | repo API |
| Forks | 2,372 | repo API |
| Open Issues | 79 | repo API |
| License | Apache-2.0 | repo API |
| 创建时间 | 2023-10-11 | repo API |
| 当前版本 | 0.16.7 | pyproject.toml |
| 描述 | "platform for building stateful agents with advanced memory" | repo API |

### MemGPT 论文

- **arXiv ID**: 2310.08560v2
- **标题**: "MemGPT: Towards LLMs as Operating Systems"
- **作者**: Charles Packer, Sarah Wooders, Kevin Lin, Vivian Fang, Shishir G. Patil, Ion Stoica, Joseph E. Gonzalez
- **核心概念**: Virtual context management — 借鉴操作系统层次化内存系统，通过 fast/slow memory 之间的数据移动提供"大内存"的假象
- **关键技术**: 利用 interrupts 管理 MemGPT 与用户之间的控制流
- **评估领域**: (1) 文档分析（超出上下文窗口的大文档）(2) 多 session 聊天（长期交互中的记忆、反思、进化）

## 2. 核心包结构

主包 `letta/` 的子模块（从 `__init__.py` 的 public API 推断，来源：`letta-init.py`）：

| 模块 | 暴露的公开类型 |
|------|---------------|
| `schemas.agent` | `AgentState` |
| `schemas.block` | `Block` |
| `schemas.memory` | `Memory`, `BasicBlockMemory`, `ChatMemory`, `ArchivalMemorySummary`, `RecallMemorySummary` |
| `schemas.message` | `Message`, `LettaMessage`, `LettaErrorMessage` |
| `schemas.tool` | `Tool` |
| `schemas.user` | `User` |
| `schemas.llm_config` | `LLMConfig` |

`pyproject.toml` 显示依赖涉及：SQLAlchemy（ORM）、SQLModel（数据模型）、Alembic（迁移）、gRPC、Temporal.io（工作流）、llama-index（RAG/检索）、OpenTelemetry（可观测性）。

## 3. 核心抽象：Block

`Block` 是 Letta 记忆系统的原子单位。定义（来源：`letta-schemas-block.py:67-86`）：

> "A Block represents a reserved section of the LLM's context window."

### 3.1 Block 的字段模型

| 字段 | 类型 | 语义 |
|------|------|------|
| `value` | str | Block 的实际文本内容 |
| `limit` | int | 字符数上限（默认 `CORE_MEMORY_BLOCK_CHAR_LIMIT`） |
| `label` | Optional[str] | 上下文窗口中的标签（如 "human", "persona"） |
| `read_only` | bool | Agent 是否只读（不可编辑） |
| `description` | Optional[str] | Block 的描述 |
| `metadata` | dict | 附加元数据 |
| `tags` | List[str] | 关联标签 |
| `hidden` | Optional[bool] | 是否在上下文中隐藏 |

### 3.2 预定义 Block 类型

| 类型 | 默认 label | 语义 |
|------|-----------|------|
| `Human` | "human" | 关于用户的信息 |
| `Persona` | "persona" | Agent 的自我认知/角色设定 |
| `FileBlock` | 动态 | Agent 当前打开的文件记忆 |

`DEFAULT_BLOCKS = [Human(value=""), Persona(value="")]` — 每个 Agent 默认携带 human 和 persona 两个 Block。

### 3.3 Block 与上下文窗口的关系

Block 的核心设计假设：**记忆不是存储在数据库里然后"检索"进上下文，记忆本身就是上下文窗口中的保留区域**。Agent 通过 `core_memory_append` 和 `core_memory_replace` 工具直接编辑自己的记忆 Block（来源：`letta-schemas-memory.py:804-837`）。

这与 Mem0 的架构形成鲜明对比：
- **Mem0**: 记忆存储在向量数据库 → 检索 → 注入系统 prompt
- **Letta**: 记忆就是上下文窗口中的 Block → Agent 直接读写 → 无需"检索"步骤

## 4. 记忆分层模型（MemGPT OS 遗产）

Letta 继承了 MemGPT 论文中的操作系统式记忆分层概念。从 `ContextWindowOverview` 和 `Memory` 类可见四层记忆（来源：`letta-schemas-memory.py:23-66`）：

| 层级 | 对应字段 | OS 类比 | 特性 |
|------|----------|---------|------|
| **Core Memory** | `core_memory`, `num_tokens_core_memory` | 寄存器/CPU 缓存 | 常驻上下文窗口，Agent 可直接编辑 |
| **Recall Memory** | `num_recall_memory` | 主存（RAM） | 近期对话历史，分页进出 |
| **Archival Memory** | `num_archival_memory` | 外存（磁盘） | 长期存储，需要显式检索 |
| **Summary Memory** | `summary_memory`, `num_tokens_summary_memory` | 交换区/缓存摘要 | 对长期记忆的压缩摘要 |

`ContextWindowOverview` 类还跟踪：
- `num_tokens_system` — 系统 prompt 占用
- `num_tokens_functions_definitions` — 工具定义占用
- `num_tokens_messages` — 当前消息列表占用
- `memory_filesystem` — Git  backed agent 的文件系统记忆（可选）

这说明 Letta 的上下文窗口管理是**精确到 token 的会计系统**，而非简单的"把历史对话塞进去"。

## 5. Memory 类层次结构

```
Memory (BaseModel)
├── blocks: List[Block]           # 核心记忆 Block
├── file_blocks: List[FileBlock]  # 文件相关 Block
└── prompt_template: str          # 已废弃

BasicBlockMemory(Memory)
├── core_memory_append()          # Agent 工具：追加 Block 内容
└── core_memory_replace()         # Agent 工具：替换 Block 内容

ChatMemory(BasicBlockMemory)
└── 默认 blocks = [persona, human]
```

### 5.1 Agent 自编辑记忆的工具设计

`core_memory_append` 和 `core_memory_replace` 的函数签名设计（来源：`letta-schemas-memory.py:804-837`）：

- **参数**: `label`（目标 Block）、`content`（追加/替换内容）
- **返回值**: 始终 `None` — 这是一个副作用操作，不生成对话响应
- **删除语义**: 用空字符串替换 = 删除
- **校验**: `replace` 要求 `old_content` 必须精确匹配，否则抛出 `ValueError`

这意味着 Agent 对记忆的操作是**显式、结构化、可审计的** — 不是隐式的"模型自己决定记住什么"。

## 6. 存储后端

`pyproject.toml` 的 optional dependencies 显示支持的数据库（来源：`letta-pyproject.toml` §Databases）：

| 后端 | 包 |
|------|-----|
| PostgreSQL + pgvector | `pgvector`, `psycopg2-binary`, `asyncpg` |
| Redis | `redis>=6.2.0` |
| Pinecone | `pinecone[asyncio]` |
| SQLite + sqlite-vec | `aiosqlite`, `sqlite-vec` |

核心 ORM 使用 SQLAlchemy + SQLModel，通过 Alembic 管理迁移。与 Mem0 不同，Letta 没有"向量存储工厂"的插件化抽象，而是直接依赖 SQLAlchemy 的底层数据库 + 向量扩展。

## 7. 关键设计取舍

| 取舍 | Letta 的选择 | 反事实 |
|------|------------|--------|
| 记忆位置 | 记忆 = 上下文窗口中的 Block（in-context） | 记忆 = 外部数据库 → 检索注入（如 Mem0/CrewAI） |
| 记忆编辑 | Agent 显式调用工具编辑 | 隐式 LLM 提取（如 Mem0 的 ADD-only） |
| 记忆分层 | OS 式四级分层（Core/Recall/Archival/Summary） | 单层统一存储 |
| Block 语义 | 带标签的保留区（human/persona/file） | 无标签的纯文本块 |
| 上下文管理 | 精确 token 会计（ContextWindowOverview） | 粗略的字符/消息数估计 |

## 8. 记忆相关的用户问题（GitHub Issues 实证）

从最近 30 个 issues 中筛选出 5 个与 memory/block 相关（来源：`letta-issues-recent.json`），典型问题：

| 类别 | 示例 Issue | 暴露的工程现实 |
|------|-----------|----------------|
| Git 同步 | #3324: GitEnabledBlockManager sync 在二进制文件上 500 错误 | Git-backed memory 的 UTF-8 假设与真实文件系统不匹配 |
| 孤儿 Block | #3323: Git sync 是 additive-only，删除/移动文件留下孤儿 Block | 与 Mem0 类似的 ADD-only 问题：清理比添加难 |
| 路径映射 | #3325: memfs path_mapping 把所有 .md 文件映射为 blocks | Block 自动生成的边界条件不明确 |
| 记忆治理 | #3320: Memory governance — policy enforcement for stateful agent memory | 用户需要审计和控制 Agent 的自编辑记忆行为 |

## 9. Mem0 vs Letta 记忆架构对照

| 维度 | Mem0 | Letta |
|------|------|-------|
| 记忆定位 | 外部独立层（向量数据库） | 核心架构抽象（上下文窗口保留区） |
| 写入方式 | LLM 自动提取（ADD-only） | Agent 显式工具调用（append/replace） |
| 用户可控性 | 低（由 extraction prompt 决定） | 高（用户可见 Block，Agent 显式编辑） |
| 检索模型 | 多信号融合（语义+BM25+实体） | OS 式分层（Core/Recall/Archival） |
| 历史审计 | SQLite history 表（全量） | 依赖数据库版本/Block 变更日志 |
| 存储后端 | 15+ 向量存储插件 | PostgreSQL/pgvector/Redis/SQLite |
| 适用场景 | 为现有 Agent 添加记忆层 | 从零构建有状态 Agent |

## Sources
- raw:.evolve/raw/letta-repo-api.json
- raw:.evolve/raw/letta-readme.md
- raw:.evolve/raw/letta-pyproject.toml
- raw:.evolve/raw/letta-init.py
- raw:.evolve/raw/letta-schemas-memory.py
- raw:.evolve/raw/letta-schemas-block.py
- raw:.evolve/raw/letta-issues-recent.json
- raw:.evolve/raw/memgpt-paper-abstract.html
- raw:.evolve/raw/memgpt-arxiv-search.xml
