# markdown-it-py

**Markdown parser for Python** | v3.0+ (latest 4.0.x) | `pip install markdown-it-py`

Python port of the JavaScript `markdown-it` parser. 100% CommonMark compliant. Parses to a token stream, then renders to HTML (or any custom format). Plugin architecture for syntax extensions.

## Quick Start

```python
from markdown_it import MarkdownIt

md = MarkdownIt()
html = md.render("# Hello\n\nThis is **bold** and *italic*.")
# '<h1>Hello</h1>\n<p>This is <strong>bold</strong> and <em>italic</em>.</p>\n'
```

## Core API

### MarkdownIt Class

```python
from markdown_it import MarkdownIt

md = MarkdownIt(
    config="commonmark",    # Preset: "commonmark", "js-default", "zero", "gfm-like"
    options_update=None,    # Dict to override preset options
    renderer_cls=None,      # Custom renderer class
)
```

**Presets:**

| Preset | Description |
|--------|-------------|
| `"commonmark"` | Default. Strict CommonMark compliance. |
| `"js-default"` | HTML parsing disabled, tables + strikethrough enabled. |
| `"zero"` | Everything disabled. Whiteboard for custom syntax. |
| `"gfm-like"` | Approximate GitHub Flavored Markdown. |

**Key methods:**

| Method | Signature | Description |
|--------|-----------|-------------|
| `render` | `render(src: str, env=None) -> str` | Parse and render to HTML |
| `parse` | `parse(src: str, env=None) -> list[Token]` | Parse to token stream |
| `renderInline` | `renderInline(src: str, env=None) -> str` | Render single paragraph (no block wrapping) |
| `parseInline` | `parseInline(src: str, env=None) -> list[Token]` | Parse inline content only |
| `enable` | `enable(names, ignoreInvalid=False)` | Enable rules by name |
| `disable` | `disable(names, ignoreInvalid=False)` | Disable rules by name |
| `use` | `use(plugin, **opts)` | Load a plugin (chainable) |
| `add_render_rule` | `add_render_rule(name, fn)` | Override rendering for a token type |

### Token Stream

Parsing returns a flat list of `Token` objects. Block tokens contain inline children.

```python
tokens = md.parse("Hello **world**")
for token in tokens:
    print(token.type, token.tag, token.nesting, token.content)
    # paragraph_open   p    1   ""
    # inline           ""   0   "Hello **world**"
    # paragraph_close  p   -1   ""
```

**Token attributes:**

| Attribute | Type | Description |
|-----------|------|-------------|
| `type` | `str` | Token type (e.g. `"heading_open"`, `"inline"`, `"fence"`) |
| `tag` | `str` | HTML tag (e.g. `"h1"`, `"p"`, `""`) |
| `nesting` | `int` | `1` = opening, `0` = self-closing, `-1` = closing |
| `content` | `str` | Raw text content |
| `children` | `list[Token] \| None` | Inline tokens for `type="inline"` |
| `attrs` | `dict` | HTML attributes (e.g. `{"href": "..."}`) |
| `info` | `str` | Fence language, etc. |
| `markup` | `str` | The delimiter used (e.g. `"**"`, `"-"`) |
| `level` | `int` | Nesting level |
| `block` | `bool` | True for block-level tokens |
| `hidden` | `bool` | If true, token is not rendered |
| `map` | `list[int]` | Source line range `[begin, end]` |

### Syntax Tree

Convert the flat token stream to a nested tree for easier traversal.

```python
from markdown_it import MarkdownIt
from markdown_it.tree import SyntaxTreeNode

md = MarkdownIt()
tokens = md.parse("# Heading\n\nParagraph with **bold**.")
tree = SyntaxTreeNode(tokens)

for node in tree.walk():
    print(node.type, node.content if node.content else "")
```

## Plugins

Plugins are functions that receive the `MarkdownIt` instance and modify it.

```python
from markdown_it import MarkdownIt
from mdit_py_plugins.front_matter import front_matter_plugin
from mdit_py_plugins.footnote import footnote_plugin

md = (
    MarkdownIt()
    .use(front_matter_plugin)
    .use(footnote_plugin)
    .enable("table")
)
html = md.render(text)
```

**Popular plugins (from `mdit-py-plugins`):**

| Plugin | Function |
|--------|----------|
| `front_matter_plugin` | YAML front matter |
| `footnote_plugin` | Footnotes |
| `deflist_plugin` | Definition lists |
| `tasklists_plugin` | `- [x]` checkboxes |
| `anchors_plugin` | Auto heading anchors |
| `attrs_plugin` | `{.class #id}` attribute syntax |
| `container_plugin` | `:::` fenced containers |
| `dollarmath_plugin` | `$...$` and `$$...$$` math |
| `wordcount_plugin` | Word count |

Install: `pip install mdit-py-plugins`

## Examples

### 1. Custom rendering for code blocks

```python
from markdown_it import MarkdownIt

md = MarkdownIt()

def render_fence(self, tokens, idx, options, env):
    token = tokens[idx]
    lang = token.info.strip() if token.info else ""
    code = token.content
    return f'<pre><code data-lang="{lang}">{code}</code></pre>\n'

md.add_render_rule("fence", render_fence)
html = md.render("```python\nprint('hello')\n```")
```

### 2. Extract all links from markdown

```python
from markdown_it import MarkdownIt

md = MarkdownIt()
tokens = md.parse("[Example](https://example.com) and [Other](https://other.com)")

links = []
for token in tokens:
    if token.children:
        for child in token.children:
            if child.type == "link_open":
                links.append(child.attrs.get("href", ""))
# links == ["https://example.com", "https://other.com"]
```

### 3. Selective parsing with zero preset

```python
from markdown_it import MarkdownIt

# Start from nothing, enable only what you need
md = MarkdownIt("zero").enable(["heading", "emphasis", "link"])
html = md.render("# Title\n\n**bold** and [link](url)")
```

## Pitfalls

- **Preset matters** -- `"commonmark"` (default) does not include tables, strikethrough, or GFM features. Use `"gfm-like"` or enable rules explicitly.
- **enable() raises on unknown rules** -- Pass `ignoreInvalid=True` if the rule might not exist (e.g. plugin not loaded yet).
- **Token stream is flat** -- Inline content is nested inside `type="inline"` tokens. Access via `token.children`, not as siblings.
- **render vs renderInline** -- `render()` wraps in block elements (`<p>`). `renderInline()` does not. Using `render()` on a single line adds `<p>` tags.
- **Plugins modify the instance** -- `use()` mutates the `MarkdownIt` instance. If you need different configurations, create separate instances.
- **Not a sanitizer** -- The parser renders raw HTML by default in some presets. Sanitize output if rendering user-supplied markdown.
