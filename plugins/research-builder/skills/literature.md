---
name: literature
description: "Search for and summarize relevant papers, theorems, or prior work. Use when the user says 'find papers about [topic]', 'what's the prior work on [X]', 'search for related work', 'what does the literature say', 'look up [paper/author]', 'has anyone done this before', or 'what's known about [X]'."
---

# literature

Use the literature subagent (defined in `agents/literature.md`) to search for
and summarize relevant academic papers, theorems, and concepts.

Provide the subagent with:
- The search query or topic
- Context about which threads or concepts this relates to
- What kind of result the researcher needs (specific paper, survey of a field,
  a particular technique, a known result to cite)

After receiving the report, link relevant findings to the concept graph
(CONCEPT_GRAPH.md) and affected thread dossiers (connections.md files).
