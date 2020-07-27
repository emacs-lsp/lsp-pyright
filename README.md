# lsp-pyright

[![Build Status](https://travis-ci.com/emacs-lsp/lsp-pyright.svg?branch=master)](https://travis-ci.com/emacs-lsp/lsp-pyright)

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

`lsp-pyright` supports the following configuration. Each configuration is descirbed in detail in [Pyright Settings](https://github.com/microsoft/pyright/blob/master/docs/settings.md).

- `pyright.disableLanguageServices` via `lsp-pyright-disable-language-services`
- `pyright.disableOrganizeImports` via `lsp-pyright-disable-organize-imports`
- `python.analysis.useLibraryCodeForTypes` via `lsp-pyright-use-library-code-for-types`
- `python.analysis.diagnosticMode` via `lsp-pyright-diagnostic-mode`
- `python.analysis.typeCheckingMode` via `lsp-pyright-typechecking-mode`
- `python.analysis.logLevel` via `lsp-pyright-log-level`
- `python.analysis.autoSearchPaths` via `lsp-pyright-auto-search-paths`

Projects can be further configured using `prightconfig.json` file. For further details please see [Pyright Configuration](https://github.com/microsoft/pyright/blob/master/docs/configuration.md).
