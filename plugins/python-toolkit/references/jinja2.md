# Jinja2 v3.1.5

## Quick Start

```python
from jinja2 import Template

template = Template("Hello, {{ name }}!")
template.render(name="World")  # "Hello, World!"
```

## Core API

```python
from jinja2 import Environment, FileSystemLoader, DictLoader

# Environment (recommended for apps)
env = Environment(
    loader=FileSystemLoader("templates/"),
    autoescape=True,            # HTML-escape by default (ALWAYS for HTML)
    trim_blocks=True,           # strip newline after block tags
    lstrip_blocks=True,         # strip leading whitespace before block tags
    undefined=StrictUndefined,  # error on undefined vars (safer)
)
template = env.get_template("page.html")
output = template.render(title="Home", items=["a", "b"])

# Loaders
FileSystemLoader("templates/")             # filesystem directory
PackageLoader("mypackage", "templates")     # Python package
DictLoader({"index.html": "{{ title }}"})   # dict of templates
ChoiceLoader([loader1, loader2])            # try multiple loaders

# Custom filters
env.filters["currency"] = lambda v: f"${v:,.2f}"
# {{ price | currency }}

# Custom globals
env.globals["now"] = datetime.utcnow
# {{ now() }}
```

### Template syntax

```jinja
{# Comments #}
{{ variable }}                              {# output variable #}
{{ user.name }}                             {# attribute access #}
{{ items[0] }}                              {# index access #}
{{ name | upper }}                          {# filter #}
{{ items | join(", ") }}                    {# filter with args #}
{{ value | default("N/A") }}               {# default value #}

{% if user.admin %}Admin{% else %}User{% endif %}
{% for item in items %}{{ item }}{% endfor %}
{% for k, v in data.items() %}{{ k }}: {{ v }}{% endfor %}

{# Template inheritance #}
{% extends "base.html" %}
{% block content %}...{% endblock %}

{# Include #}
{% include "header.html" %}

{# Macros (reusable template functions) #}
{% macro input(name, type="text") %}
    <input type="{{ type }}" name="{{ name }}">
{% endmacro %}
{{ input("username") }}

{# Set variables #}
{% set greeting = "Hello" %}

{# Whitespace control #}
{%- if true -%}trimmed{%- endif -%}
```

### Common filters

```
{{ s | upper }} / {{ s | lower }} / {{ s | title }} / {{ s | capitalize }}
{{ s | trim }} / {{ s | striptags }}
{{ s | truncate(80) }} / {{ s | wordwrap(72) }}
{{ list | join(", ") }} / {{ list | sort }} / {{ list | reverse }}
{{ list | first }} / {{ list | last }} / {{ list | length }}
{{ value | int }} / {{ value | float }} / {{ value | string }}
{{ html | safe }}                           {# mark as safe (no escape) #}
{{ data | tojson }}                          {# JSON encode #}
{{ value | default("fallback") }}
```

## Examples

### Template inheritance

```jinja
{# base.html #}
<!DOCTYPE html>
<html>
<head><title>{% block title %}{% endblock %}</title></head>
<body>{% block content %}{% endblock %}</body>
</html>

{# page.html #}
{% extends "base.html" %}
{% block title %}{{ page_title }}{% endblock %}
{% block content %}<h1>{{ page_title }}</h1><p>{{ body }}</p>{% endblock %}
```

### Code/config generation (non-HTML)

```python
env = Environment(
    loader=FileSystemLoader("templates/"),
    autoescape=False,           # no HTML escaping for code gen
    keep_trailing_newline=True, # preserve final newline
)
config = env.get_template("nginx.conf.j2").render(server_name="example.com", port=8080)
```

### Sandboxed execution

```python
from jinja2.sandbox import SandboxedEnvironment
env = SandboxedEnvironment()
# Prevents access to dangerous attributes (__class__, etc.)
```

## Pitfalls

- **Autoescape off by default**: ALWAYS set `autoescape=True` for HTML templates. Use `{{ value | safe }}` to opt out per-value.
- **`StrictUndefined`**: default `Undefined` silently renders empty string for missing vars. Use `StrictUndefined` for safety.
- **Variable scoping in loops**: variables set inside `{% for %}` are scoped to the loop. Use `namespace` for outer mutation.
- **Whitespace**: use `trim_blocks=True, lstrip_blocks=True` to avoid extra blank lines around block tags.
- **Template not found**: check that loader path is correct and template name matches exactly (case-sensitive).
- **`{{ }}` in non-HTML**: works for any text format (YAML, TOML, Python, shell scripts, etc.).
