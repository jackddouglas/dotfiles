---
name: web-search
description: Search the web using Tavily API. Use when the user asks to look something up, find documentation, check facts, or research any topic online.
---

# Web Search

Search the web and get summarized results with source URLs.

## Usage

```bash
./search.sh "your search query"           # Default 5 results
./search.sh "your search query" 10        # Up to 10 results
```

The output includes:
- An AI-generated **answer** summarizing the search results
- Individual **results** with title, URL, and content snippet

## Examples

```bash
./search.sh "nix flake best practices 2025"
./search.sh "jujutsu vcs rebase workflow"
./search.sh "rust async trait object 2025" 3
```

## Requirements

- `TAVILY_API_KEY` environment variable (supports `op://` 1Password references)
- `curl`, `jq` (available in the environment)
