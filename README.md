# ratex.el

An Emacs-focused project built around the upstream RaTeX engine.

## Repository layout

- `vendor/ratex-core`: upstream RaTeX repository, kept as a git submodule
- `backend/`: Rust backend process for editor integrations
- `docs/`: planning notes and project documentation
- `lisp/`: Emacs Lisp package sources
- `bin/`: helper scripts for local development
- `test/`: Emacs-side tests

## Current status

This repository now contains a minimal end-to-end prototype:

- a standalone JSONL backend that renders LaTeX fragments to SVG
- an Emacs minor mode with async inline previews
- basic math fragment detection and overlay display

## Getting started

Start the backend manually:

```bash
bin/dev-start-backend.sh
```

Or enable `ratex-mode` in Emacs and let it launch the backend through Cargo.
