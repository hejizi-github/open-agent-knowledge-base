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
