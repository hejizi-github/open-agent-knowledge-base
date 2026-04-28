---
id: project-context-33110ab7122c
type: offline-source-pack
captured_at: 2026-04-28T10:20:22Z
project: open-agent-knowledge-base
git_head: 24372fe
source_fingerprint: 33110ab7122c
---

# Offline Project Source Pack

This source pack is generated from local project files so Step B can proceed when network access or DNS is unavailable.

## Goal

持续学习开源 Agent 项目，沉淀可复用知识库，持续产出面向中文读者的深度万字长文；每篇文章必须图文并茂，图片只输出可直接用于生图的提示词，不直接生成图片。

## File Index

- .gitignore
- README.md
- articles/drafts/five-pole-agent-frameworks-outline.md
- articles/drafts/five-pole-agent-frameworks-sec0.md
- articles/drafts/five-pole-agent-frameworks-sec1.md
- articles/drafts/five-pole-agent-frameworks-sec10.md
- articles/drafts/five-pole-agent-frameworks-sec2.md
- articles/drafts/five-pole-agent-frameworks-sec3.md
- articles/drafts/five-pole-agent-frameworks-sec4.md
- articles/drafts/five-pole-agent-frameworks-sec5.md
- articles/drafts/five-pole-agent-frameworks-sec6.md
- articles/drafts/five-pole-agent-frameworks-sec7.md
- articles/drafts/five-pole-agent-frameworks-sec8.md
- articles/drafts/five-pole-agent-frameworks-sec9.md
- articles/drafts/openhands-architecture-outline.md
- articles/drafts/openhands-architecture-sec0.md
- articles/drafts/openhands-architecture-sec1.md
- articles/drafts/openhands-architecture-sec2.md
- articles/drafts/openhands-architecture-sec3.md
- articles/drafts/openhands-architecture-sec4.md
- articles/drafts/openhands-architecture-sec5.md
- articles/drafts/openhands-architecture-sec6.md
- articles/drafts/smolagents-vs-langgraph-outline.md
- articles/drafts/smolagents-vs-langgraph.md
- articles/index.md
- articles/published/five-pole-agent-frameworks.md
- articles/published/openhands-architecture.md
- articles/published/smolagents-vs-langgraph.md
- articles/templates/deep-agent-essay.md
- image-prompts/five-pole-agent-frameworks.md
- image-prompts/index.md
- image-prompts/openhands-architecture.md
- image-prompts/smolagents-vs-langgraph.md
- image-prompts/templates/agent-article-visuals.md
- knowledge-base/index.md
- knowledge-base/rubrics/agent-project-analysis.md
- knowledge-base/sources/open-source-agent-projects.md

## README.md

```
# Open Agent Knowledge Base

This project continuously studies open-source agent projects and turns the
findings into reusable knowledge-base documents and long-form Chinese essays.

## Output Contract

- `knowledge-base/`: structured project notes, architecture comparisons,
  design patterns, failure modes, evaluation rubrics, and source indexes.
- `articles/`: deep Chinese essays. Target length: 10,000+ Chinese characters
  when the evidence base is ready.
- `image-prompts/`: image generation prompts for diagrams, covers, conceptual
  illustrations, architecture visuals, and section graphics.
- `.evolve/wiki/`: compiled LLM Wiki pages synthesized from raw sources.

## Research Scope

Prioritize open-source projects that materially shaped agent design:

- LangGraph
- AutoGen
- CrewAI
- OpenHands
- Semantic Kernel
- AutoGPT
- MetaGPT
- Haystack agents
- LlamaIndex agents/workflows
- Dify agent/workflow runtime

Agents must verify repository URLs, current docs, and project status before
using any claim in an article.

## Article Standard

Each article should be written for experienced builders, not beginners. It must:

- explain the architecture and design tradeoffs;
- compare at least 3 projects when making cross-project claims;
- include source-backed project facts;
- include failure modes and practical implementation lessons;
- include image prompt blocks where visuals would help;
- separate verified facts from interpretation.
```

## Code Skeleton

