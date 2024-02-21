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

lsp-mode client leveraging [Pyright language server](https://github.com/microsoft/pyright)

## Quickstart

```emacs-lisp
(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))  ; or lsp-deferred
```

## Configuration

`lsp-pyright` supports the following configuration. Each configuration is described in detail in
[Pyright Settings](https://github.com/microsoft/pyright/blob/master/docs/settings.md).

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

## Usage notes

Pyright includes a recent copy of the Python stdlib type stubs. To add type stubs for additional
libraries, customize `lsp-pyright-stub-path`, or place the appropriate type stubs in `typings`
subdirectory of your project (this is the default stub path). Note that without stubs but with
`lsp-pyright-use-library-code-for-types` non-nil, you may see type checking errors, particularly
for complex libraries such as Pandas.

Example setup to get typechecking working properly for Pandas:

```shell
git clone https://github.com/microsoft/python-type-stubs $HOME/src
```

```emacs-lisp
  (setq lsp-pyright-use-library-code-for-types t) ;; set this to nil if getting too many false positive type errors
  (setq lsp-pyright-stub-path (concat (getenv "HOME") "/src/python-type-stubs")) ;; example
```
