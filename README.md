# lsp-pyright

[![Build Status](https://github.com/emacs-lsp/lsp-pyright/workflows/CI/badge.svg?branch=master)](https://github.com/emacs-lsp/lsp-pyright/actions)
[![License](http://img.shields.io/:License-GPL3-blue.svg)](License)
[![MELPA](https://melpa.org/packages/lsp-pyright-badge.svg)](https://melpa.org/#/lsp-pyright)
[![Join the chat at https://gitter.im/emacs-lsp/lsp-mode](https://badges.gitter.im/emacs-lsp/lsp-mode.svg)](https://gitter.im/emacs-lsp/lsp-mode?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->

## Table of Contents

- [Quickstart](#quickstart)
- [Configuration](#configuration)
- [Usage notes](#usage-notes)

<!-- markdown-toc end -->

lsp-mode client leveraging [pyright](https://github.com/microsoft/pyright) and [basedpyright](https://github.com/DetachHead/basedpyright) language server.

## Quickstart

```emacs-lisp
(use-package lsp-pyright
  :ensure t
  :custom (lsp-pyright-langserver-command "pyright") ;; or basedpyright
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))  ; or lsp-deferred
```

## Configuration

`lsp-pyright` supports the following configuration. Each configuration is described in detail in
[Pyright Settings](https://github.com/microsoft/pyright/blob/master/docs/settings.md).

- `basedpyright.` / `pyright.disableLanguageServices` via `lsp-pyright-disable-language-services`
- `basedpyright.` / `pyright.disableOrganizeImports` via `lsp-pyright-disable-organize-imports`
- `basedpyright.` / `pyright.disableTaggedHints` via `lsp-pyright-disable-tagged-hints`
- `basedpyright.` / `python.typeCheckingMode` via `lsp-pyright-type-checking-mode`
- `basedpyright.analysis.inlayHints.variableTypes` via `lsp-pyright-basedpyright-inlay-hints-variable-types`
- `basedpyright.analysis.inlayHints.callArgumentNames` via `lsp-pyright-basedpyright-inlay-hints-call-argument-names`
- `basedpyright.analysis.inlayHints.functionReturnTypes` via `lsp-pyright-basedpyright-inlay-hints-function-return-types`
- `basedpyright.analysis.inlayHints.genericTypes` via `lsp-pyright-basedpyright-inlay-hints-generic-types`
- `python.analysis.autoImportCompletions` via `lsp-pyright-auto-import-completions`
- `python.analysis.diagnosticMode` via `lsp-pyright-diagnostic-mode`
- `python.analysis.logLevel` via `lsp-pyright-log-level`
- `python.analysis.autoSearchPaths` via `lsp-pyright-auto-search-paths`
- `python.analysis.extraPaths` via `lsp-pyright-extra-paths`
- `python.pythonPath` via `lsp-pyright-locate-python`
- `python.venvPath` via `lsp-pyright-venv-path`

Projects can be further configured using `pyrightconfig.json` file. For further details please see
[Pyright Configuration](https://github.com/microsoft/pyright/blob/master/docs/configuration.md).

## Choosing the correct version of Python

`lsp-pyright` will try its best to select the correct version of the
python executable to use. It will do so by iteratively executing
different search functions, going from most precise to most
general.

The list and order of the list can be modified by customizing
`lsp-pyright-python-search-functions`. By default the order is:
 - Look for a parent directory with a virtual-environment named
   `.venv` or `venv` via `lsp-pyright--locate-python-venv`.
 - Look for a python executable on your PATH via
   `lsp-pyright--locate-python-python`.
