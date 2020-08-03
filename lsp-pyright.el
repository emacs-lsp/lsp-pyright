;;; lsp-pyright.el --- Python LSP client using Pyright -*- lexical-binding: t; -*-

;; Copyright (C) 2020 emacs-lsp maintainers

;; Author: Arif Rezai, Vincent Zhang, Andrew Christianson
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1") (lsp-mode "7.0") (dash "2.14.1") (ht "2.0"))
;; Homepage: https://github.com/emacs-lsp/lsp-pyright
;; Keywords: languages, tools, lsp


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Pyright language server.
;;
;;; Code:

(require 'lsp-mode)
(require 'dash)
(require 'ht)

;; Group declaration
(defgroup lsp-pyright nil
  "LSP support for python using the Pyright Language Server."
  :group 'lsp-mode
  :link '(url-link "https://github.com/microsoft/pyright"))

(defcustom lsp-pyright-langserver-command-args '("--stdio")
  "Command to start pyright-langserver."
  :type '(repeat string)
  :group 'lsp-pyright)

(defcustom lsp-pyright-disable-language-services nil
  "Disables all language services except for \"hover\"."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-disable-organize-imports nil
  "Disables the \"Organize Imports\" command."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-use-library-code-for-types nil
  "Determines whether pyright reads, parses and analyzes library code to
extract type information in the absence of type stub files.
This can add significant overhead and may result in poor-quality type information.
The default value for this option is false."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-diagnostic-mode "openFilesOnly"
  "Determines whether pyright analyzes (and reports errors for) all files
in the workspace, as indicated by the config file.
If this option is set to \"openFilesOnly\", pyright analyzes only open files."
  :type '(choice
          (const "openFilesOnly")
          (const "workspace"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-typechecking-mode "basic"
  "Determines the default type-checking level used by pyright.
This can be overridden in the configuration file"
  :type '(choice
          (const "off")
          (const "basic")
          (const "strict"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-log-level "info"
  "Determines the default type-checking level used by pyright.
This can be overridden in the configuration file"
  :type '(choice
          (const "error")
          (const "warning")
          (const "info")
          (const "trace"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-auto-search-paths t
  "Determines whether pyright automatically adds common search paths like \"src\"
if there are no execution environments defined in the config file."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-extra-paths []
  "Paths to add to the default execution environment extra paths if there are no execution environments defined in the config file."
  :type 'lsp-string-vector
  :group 'lsp-pyright)
(make-variable-buffer-local 'lsp-pyright-extra-paths)

(defcustom lsp-pyright-multi-root t
  "If non nil, lsp-pyright will be started in multi-root mode."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-python-executable-cmd "python"
  "Command to specify the Python command for the Microsoft Python Language Server.
Similar to the `python-shell-interpreter', but used only with mspyls.
Useful when there are multiple python versions in system.
e.g, there are `python2' and `python3', both in system PATH,
and the default `python' links to python2,
set as `python3' to let ms-pyls use python 3 environments."
  :type 'string
  :group 'lsp-pyright)

(defun lsp-pyright-locate-python ()
  "Look for virtual environments local to the workspace"
  (let* ((venv (locate-dominating-file default-directory "venv/"))
         (sys-python (executable-find lsp-pyright-python-executable-cmd))
         (venv-python (f-expand "venv/bin/python" venv)))
    (cond
     ((and venv (f-executable? venv-python)) venv-python)
     (sys-python))))

(defun lsp-pyright--begin-progress-callback (workspace &rest _)
  (with-lsp-workspace workspace
    (--each (lsp--workspace-buffers workspace)
      (when (buffer-live-p it)
        (with-current-buffer it
          (lsp--spinner-start)))))
  (lsp--info "Pyright language server is analyzing..."))

(defun lsp-pyright--report-progress-callback (_workspace params)
  "Log progress information."
  (when (and (arrayp params) (> (length params) 0))
    (lsp-log (aref params 0))))

(defun lsp-pyright--end-progress-callback (workspace &rest _)
  (with-lsp-workspace workspace
    (--each (lsp--workspace-buffers workspace)
      (when (buffer-live-p it)
        (with-current-buffer it
          (lsp--spinner-stop))))
    (lsp--info "Pyright language server is analyzing...done")))

(lsp-register-custom-settings
 `(("pyright.disableLanguageServices" lsp-pyright-disable-language-services)
   ("pyright.disableOrganizeImports" lsp-pyright-disable-organize-imports)
   ("python.analysis.useLibraryCodeForTypes" lsp-pyright-use-library-code-for-types)
   ("python.analysis.diagnosticMode" lsp-pyright-diagnostic-mode)
   ("python.analysis.typeCheckingMode" lsp-pyright-typechecking-mode)
   ("python.analysis.logLevel" lsp-pyright-log-level)
   ("python.analysis.autoSearchPaths" lsp-pyright-auto-search-paths)
   ("python.analysis.extraPaths" lsp-pyright-extra-paths)
   ("python.pythonPath" lsp-pyright-locate-python)))

(lsp-dependency 'pyright
                '(:system "pyright-langserver")
                '(:npm :package "pyright"
                       :path "pyright-langserver"))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection (lambda ()
                                          (cons (lsp-package-path 'pyright)
                                                lsp-pyright-langserver-command-args)))
  :major-modes '(python-mode)
  :server-id 'pyright
  :multi-root lsp-pyright-multi-root
  :priority 3
  :initialization-options (lambda () (ht-merge (lsp-configuration-section "pyright")
                                               (lsp-configuration-section "python")))
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      (lsp--set-configuration
                       (ht-merge (lsp-configuration-section "pyright")
                                 (lsp-configuration-section "python")))))
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (lsp-package-ensure 'pyright callback error-callback))
  :notification-handlers (lsp-ht ("pyright/beginProgress" 'lsp-pyright--begin-progress-callback)
                                 ("pyright/reportProgress" 'lsp-pyright--report-progress-callback)
                                 ("pyright/endProgress" 'lsp-pyright--end-progress-callback))))

(provide 'lsp-pyright)
;;; lsp-pyright.el ends here
