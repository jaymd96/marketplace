# lark v1.2.2

## Quick Start

```python
from lark import Lark

grammar = """
    start: NAME "=" value
    value: NUMBER | STRING
    NAME: /[a-zA-Z_]\w*/
    STRING: /"[^"]*"/
    NUMBER: /\d+(\.\d+)?/
    %ignore /\s+/
"""
parser = Lark(grammar)
tree = parser.parse('x = 42')
print(tree.pretty())
```

## Core API

```python
from lark import Lark, Transformer, v_args, Token, Tree

# Create parser
parser = Lark(grammar_string,
    parser="earley",        # "earley" (default, handles ambiguity) or "lalr" (faster)
    start="start",          # start rule
    ambiguity="explicit",   # "explicit" or "resolve"
)
tree = parser.parse("input text")

# Tree and Token
tree.data                   # rule name (str)
tree.children               # list of Tree and Token children
token.type                  # terminal name (str, UPPERCASE)
token.value                 # matched text (str)
tree.pretty()               # human-readable tree

# Transformer (bottom-up tree processing)
@v_args(inline=True)        # children as positional args instead of list
class MyTransformer(Transformer):
    def rule_name(self, *children):
        return processed_value
    def TERMINAL_NAME(self, token):
        return transformed_token
result = MyTransformer().transform(tree)
```

### Grammar syntax

```
rule: item1 item2           # sequence
    | alternative            # choice
item?                        # optional
item*                        # zero or more
item+                        # one or more
item ~ 3                     # exactly 3
item ~ 2..5                  # 2 to 5

TERMINAL: /regex/            # regex terminal
TERMINAL: "literal"          # string literal
?rule: ...                   # inline rule (removed from tree)
!rule: ...                   # keep all tokens in tree

%import common.NUMBER        # import from built-in common grammar
%import common.WS
%ignore WS                   # ignore whitespace
```

### Common grammar imports

```
%import common.NUMBER        # integer or decimal
%import common.INT           # integer only
%import common.FLOAT         # float only
%import common.WORD          # word characters
%import common.ESCAPED_STRING # "quoted string with escapes"
%import common.NEWLINE
%import common.WS            # whitespace
%import common.WS_INLINE     # whitespace (no newlines)
```

## Examples

### Calculator with Transformer

```python
grammar = """
    start: expr
    ?expr: term (("+"|"-") term)*
    ?term: factor (("*"|"/") factor)*
    ?factor: NUMBER | "(" expr ")"
    NUMBER: /\d+(\.\d+)?/
    %ignore /\s+/
"""
parser = Lark(grammar)

@v_args(inline=True)
class CalcTransformer(Transformer):
    def start(self, expr): return expr
    def NUMBER(self, token): return float(token)

tree = parser.parse("2 + 3 * 4")
```

### JSON parser

```python
grammar = r"""
    start: value
    ?value: object | array | STRING | NUMBER | "true" | "false" | "null"
    object: "{" (pair ("," pair)*)? "}"
    pair: STRING ":" value
    array: "[" (value ("," value)*)? "]"
    STRING: /\"[^\"]*\"/
    NUMBER: /-?\d+(\.\d+)?/
    %ignore /\s+/
"""
```

## Pitfalls

- **Terminals UPPERCASE, rules lowercase**: mixing them causes parse errors or unexpected behavior.
- **`?` prefix inlines rules**: `?expr: term` removes the `expr` node, promoting children. Use for cleaner trees.
- **LALR vs Earley**: LALR is 5-10x faster but cannot handle ambiguous grammars. Default Earley handles everything.
- **Whitespace handling**: must explicitly `%ignore /\s+/` or handle WS in grammar.
- **Transformer method names must match rule/terminal names**: typos silently leave nodes unprocessed.
- **`@v_args(inline=True)`**: pass children as positional args. Without it, receive a single list.
