# LLM Wiki Schema

LLM Wiki is a compiled knowledge layer maintained by agents.

## Hard Definition

- `raw/` is immutable source material. Agents may append new sources but must not rewrite captured sources.
- `wiki/` is synthesized knowledge compiled from raw sources. It is not a dump of excerpts.
- `schema/` defines page formats, ingest/query/lint rules, and promotion rules.
- `wiki/index.md` is the navigation surface. Agents read it before selecting pages.
- `wiki/log.md` records ingest, query, lint, and promotion events.

## Required Operations

1. `ingest`: capture source into `raw/`, then update relevant wiki pages, index, and log.
2. `query`: read index and selected wiki pages to frame the current task.
3. `lint`: check missing sources, stale pages, orphan pages, weak links, and contradictions.
4. `promote`: graduate reusable project knowledge into the global wiki after review.

## Page Requirements

Every wiki page must include:

- `Sources` section with at least one `raw:` or `global:` reference.
- At least one link to another wiki page when a related page exists.
- A current synthesis, not only pasted source notes.

Expert pages must also include:

- `Expert Questions`
- `Quality Criteria`
- `Failure Modes`
- `Verification Methods`

## Layering

Global wiki stores cross-project expert experience. Project wiki stores local facts,
decisions, and overlays. Project facts override global defaults; raw sources override wiki synthesis.
