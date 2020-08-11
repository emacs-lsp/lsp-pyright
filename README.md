# lsp-pyright

[![Build Status](https://github.com/emacs-lsp/lsp-pyright/workflows/CI/badge.svg?branch=master)](https://github.com/emacs-lsp/lsp-pyright/actions)
[![MELPA](https://melpa.org/packages/lsp-pyright-badge.svg)](https://melpa.org/#/lsp-pyright)
[![License](http://img.shields.io/:license-gpl3-blue.svg)](LICENSE)
[![Join the chat at https://gitter.im/emacs-lsp/lsp-mode](https://badges.gitter.im/emacs-lsp/lsp-mode.svg)](https://gitter.im/emacs-lsp/lsp-mode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

lsp-mode client leveraging [Pyright language server](https://github.com/microsoft/pyright)

### Quickstart

``` emacs-lisp
(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))  ; or lsp-deferred
```

### Configuration

`lsp-pyright` supports the following configuration. Each configuration is described in detail in [Pyright Settings](https://github.com/microsoft/pyright/blob/master/docs/settings.md).

- `pyright.disableLanguageServices` via `lsp-pyright-disable-language-services`
- `pyright.disableOrganizeImports` via `lsp-pyright-disable-organize-imports`
- `python.analysis.autoImportCompletions` via `lsp-pyright-auto-import-completions`
- `python.analysis.useLibraryCodeForTypes` via `lsp-pyright-use-library-code-for-types`
- `python.analysis.typeshedPaths` via `lsp-pyright-typeshed-paths`
- `python.analysis.diagnosticMode` via `lsp-pyright-diagnostic-mode`
- `python.analysis.typeCheckingMode` via `lsp-pyright-typechecking-mode`
- `python.analysis.logLevel` via `lsp-pyright-log-level`
- `python.analysis.autoSearchPaths` via `lsp-pyright-auto-search-paths`
- `python.analysis.extraPaths` via `lsp-pyright-extra-paths`
- `python.venvPath` via `lsp-pyright-venv-path`

Projects can be further configured using `prightconfig.json` file. For further details please see [Pyright Configuration](https://github.com/microsoft/pyright/blob/master/docs/configuration.md).
