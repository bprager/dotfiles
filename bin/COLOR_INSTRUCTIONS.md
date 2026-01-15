# Instructions: Colored & Highlighted Text for PDF Reports

**Goal:** Generate a PDF via Pandoc where text can be colored or highlighted using simple Markdown syntax.

## 1. Syntax

Use standard Pandoc bracket syntax `[Text]{.class}`.

### A. Text Color
Apply one of the supported color classes.
* `[Project Alpha is complete]{.green}`
* `[Critical Error]{.red}`

### B. Background Highlight
Apply the `.highlight` class to add a yellow background (like a marker).
* `[Review this section]{.highlight}`

### C. Combined (Color + Highlight)
You can combine classes by separating them with a space inside the curly braces.
* `[CRITICAL FAILURE]{.red .highlight}`

---

## 2. Supported Color Palette (16 Colors)
The Lua script maps the following simple class names to professional LaTeX colors (requiring `dvipsnames`).

| Class Name | LaTeX Result | Best Use Case |
| :--- | :--- | :--- |
| `.red` | Red | Critical errors, Blockers |
| `.green` | ForestGreen | Success, On Track (readable) |
| `.blue` | Blue | Information, Links |
| `.yellow` | Orange | Warnings (remapped for visibility) |
| `.orange` | Orange | Delayed, Attention needed |
| `.purple` | Violet | Notes, Comments |
| `.navy` | NavyBlue | Headers, Deep Dives |
| `.maroon` | Maroon | Urgent, High Priority |
| `.teal` | TealBlue | Sub-headers, Distinct data |
| `.olive` | OliveGreen | Financial positives, Status |
| `.cyan` | Cyan | Technical highlights |
| `.magenta` | Magenta | Visual emphasis |
| `.brown` | Brown | Legacy items |
| `.lime` | LimeGreen | Bright positive indicators |
| `.gray` | Gray | Drafts, Deprecated items |
| `.darkgray`| DarkGray | Subtitles |

---

## 3. Required Document Header
Your Markdown file **must** include the following YAML frontmatter. You must enable `[dvipsnames]` for the extended color palette to work.

```markdown
---
title: "Project Status Report"
date: \today
header-includes:
 - \usepackage[dvipsnames]{xcolor}
---
