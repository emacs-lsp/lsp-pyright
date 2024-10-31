;;; lsp-pyright.el --- Python LSP client using Pyright -*- lexical-binding: t; -*-

;; Copyright (C) 2020 emacs-lsp maintainers

;; Author: Arif Rezai, Vincent Zhang, Andrew Christianson
;; Version: 0.3.0
;; Package-Requires: ((emacs "26.1") (lsp-mode "7.0") (dash "2.18.0") (ht "2.0"))
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
;; see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Pyright language server.
;;
;;; Code:

(require 'lsp-mode)
(require 'dash)
(require 'ht)
(require 'cl-lib)

;; Group declaration
(defgroup lsp-pyright nil
  "LSP support for python using the Pyright Language Server."
  :group 'lsp-mode
  :link '(url-link "https://github.com/microsoft/pyright")
  :link '(url-link "https://github.com/DetachHead/basedpyright"))

(defcustom lsp-pyright-langserver-command "pyright"
  "Choose whether to use Pyright or the BasedPyright fork."
  :type '(choice
          (const "pyright")
          (const "basedpyright"))
  :group 'lsp-pyright)

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


(defcustom lsp-pyright-disable-tagged-hints nil
  "Disables grayed out special hint diagnostics tags."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-diagnostic-mode "openFilesOnly"
  "Determines pyright diagnostic mode.
Whether pyright analyzes (and reports errors for) all files
in the workspace, as indicated by the config file.
If this option is set to \"openFilesOnly\", pyright analyzes only open files."
  :type '(choice
          (const "openFilesOnly")
          (const "workspace"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-type-checking-mode "standard"
  "Specifies the default rule set to use.

\"off\" disables all type-checking rules, but Python syntax and semantic
errors are still reported. \"all\" reports all errors in basedpyright,
but is not supported by pyright. "
  :type '(choice
          (const :tag "Off" "off")
          (const :tag "Basic" "basic")
          (const :tag "Standard" "standard")
          (const :tag "Strict" "strict")
          (const :tag "All (basedpyright only)" "all"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-log-level "info"
  "Determines the default log level used by pyright.
This can be overridden in the configuration file."
  :type '(choice
          (const "error")
          (const "warning")
          (const "info")
          (const "trace"))
  :group 'lsp-pyright)

(defcustom lsp-pyright-auto-search-paths t
  "Determines whether pyright automatically adds common search paths.
i.e: Paths like \"src\" if there are no execution environments defined in the
config file."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-extra-paths []
  "Paths to add to the default execution environment extra paths.
If there are no execution environments defined in the config file."
  :type 'lsp-string-vector
  :group 'lsp-pyright)
(make-variable-buffer-local 'lsp-pyright-extra-paths)

(defcustom lsp-pyright-auto-import-completions t
  "Determines whether pyright offers auto-import completions."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-venv-path nil
  "Path to folder with subdirectories that contain virtual environments.
Virtual Envs specified in pyrightconfig.json will be looked up in this path."
  :type '(choice (const :tag "None" nil) file)
  :group 'lsp-pyright)

(defcustom lsp-pyright-venv-directory nil
  "Folder with subdirectories that contain virtual environments.
Virtual Envs specified in pyrightconfig.json will be looked up in this path."
  :type '(choice (const :tag "None" nil) directory)
  :group 'lsp-pyright)

(defcustom lsp-pyright-multi-root t
  "If non nil, lsp-pyright will be started in multi-root mode."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-python-executable-cmd "python"
  "Command to specify the Python command for pyright.
Similar to the `python-shell-interpreter', but used only with mspyls.
Useful when there are multiple python versions in system.
e.g, there are `python2' and `python3', both in system PATH,
and the default `python' links to python2,
set as `python3' to let ms-pyls use python 3 environments."
  :type 'string
  :group 'lsp-pyright)

(defcustom lsp-pyright-prefer-remote-env t
  "If non nil, lsp-pyright will prefer remote python environment.
Only available in Emacs 27 and above."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-python-search-functions
  '(lsp-pyright--locate-python-venv
    lsp-pyright--locate-python-python)
  "List of functions to search for python executable."
  :type 'list
  :group 'lsp-pyright)

(defcustom lsp-pyright-basedpyright-inlay-hints-variable-types t
  "Whether to show inlay hints on assignments to variables.

Basedpyright only."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-basedpyright-inlay-hints-call-argument-names t
  "Whether to show inlay hints on function arguments.

Basedpyright only."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-basedpyright-inlay-hints-function-return-types t
  "Whether to show inlay hints on function return types.

Basedpyright only."
  :type 'boolean
  :group 'lsp-pyright)

(defcustom lsp-pyright-basedpyright-inlay-hints-generic-types nil
  "Whether to show inlay hints on inferred generic types.

Basedpyright only."
  :type 'boolean
  :group 'lsp-pyright)

(defun lsp-pyright--locate-venv ()
  "Look for virtual environments local to the workspace."
  (or lsp-pyright-venv-path
      (and lsp-pyright-venv-directory
           (-when-let (venv-base-directory (locate-dominating-file default-directory lsp-pyright-venv-directory))
             (concat venv-base-directory lsp-pyright-venv-directory)))
      (-when-let (venv-base-directory (locate-dominating-file default-directory "venv/"))
        (concat venv-base-directory "venv"))
      (-when-let (venv-base-directory (locate-dominating-file default-directory ".venv/"))
        (concat venv-base-directory ".venv"))))

(defun lsp-pyright--locate-python-venv ()
  "Find a python executable based on the current virtual environment."
  (executable-find (f-expand "bin/python" (lsp-pyright--locate-venv))))

(defun lsp-pyright--locate-python-python ()
  "Find a python executable based on the version of python on the PATH."
  (with-no-warnings
    (if (>= emacs-major-version 27)
        (executable-find lsp-pyright-python-executable-cmd lsp-pyright-prefer-remote-env)
      (executable-find lsp-pyright-python-executable-cmd))))

(defun lsp-pyright-locate-python ()
  "Find a python executable cmd for the workspace."
  (cl-some #'funcall lsp-pyright-python-search-functions))

(defun lsp-pyright--begin-progress-callback (workspace &rest _)
  "Log begin progress information.
Current LSP WORKSPACE should be passed in."
  (when lsp-progress-via-spinner
    (with-lsp-workspace workspace
      (--each (lsp--workspace-buffers workspace)
        (when (buffer-live-p it)
          (with-current-buffer it
            (lsp--spinner-start))))))
  (lsp-log "Pyright language server is analyzing..."))

(defun lsp-pyright--report-progress-callback (_workspace params)
  "Log report progress information.
First element of PARAMS will be passed into `lsp-log'."
  (when (and (arrayp params) (> (length params) 0))
    (lsp-log (aref params 0))))

(defun lsp-pyright--end-progress-callback (workspace &rest _)
  "Log end progress information.
Current LSP WORKSPACE should be passed in."
  (when lsp-progress-via-spinner
    (with-lsp-workspace workspace
      (--each (lsp--workspace-buffers workspace)
        (when (buffer-live-p it)
          (with-current-buffer it
            (lsp--spinner-stop))))))
  (lsp-log "Pyright language server is analyzing...done"))

(defun lsp-pyright-organize-imports ()
  "Organize imports in current buffer."
  (interactive)
  (lsp-send-execute-command (concat lsp-pyright-langserver-command ".organizeimports")
                            (vector (concat "file://" (buffer-file-name)))))

(lsp-register-custom-settings
 `((,(concat lsp-pyright-langserver-command ".disableLanguageServices") lsp-pyright-disable-language-services t)
   (,(concat lsp-pyright-langserver-command ".disableOrganizeImports") lsp-pyright-disable-organize-imports t)
   (,(concat lsp-pyright-langserver-command ".disableTaggedHints") lsp-pyright-disable-tagged-hints t)
   (,(concat lsp-pyright-langserver-command ".typeCheckingMode") lsp-pyright-type-checking-mode)
   ("basedpyright.analysis.inlayHints.variableTypes" lsp-pyright-basedpyright-inlay-hints-variable-types t)
   ("basedpyright.analysis.inlayHints.callArgumentNames" lsp-pyright-basedpyright-inlay-hints-call-argument-names t)
   ("basedpyright.analysis.inlayHints.functionReturnTypes" lsp-pyright-basedpyright-inlay-hints-function-return-types t)
   ("basedpyright.analysis.inlayHints.genericTypes" lsp-pyright-basedpyright-inlay-hints-generic-types t)
   ("python.analysis.typeCheckingMode" lsp-pyright-type-checking-mode)
   ("python.analysis.autoImportCompletions" lsp-pyright-auto-import-completions t)
   ("python.analysis.diagnosticMode" lsp-pyright-diagnostic-mode)
   ("python.analysis.logLevel" lsp-pyright-log-level)
   ("python.analysis.autoSearchPaths" lsp-pyright-auto-search-paths t)
   ("python.analysis.extraPaths" lsp-pyright-extra-paths)
   ("python.pythonPath" lsp-pyright-locate-python)
   ;; We need to send empty string, otherwise  pyright-langserver fails with parse error
   ("python.venvPath" (lambda () (or lsp-pyright-venv-path "")))))

(lsp-dependency 'pyright
                `(:system ,(concat lsp-pyright-langserver-command "-langserver"))
                `(:npm :package ,lsp-pyright-langserver-command
                  :path ,(concat lsp-pyright-langserver-command "-langserver")))

(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection (lambda ()
                                          (cons (lsp-package-path 'pyright)
                                                lsp-pyright-langserver-command-args)))
  :major-modes '(python-mode python-ts-mode)
  :server-id 'pyright
  :multi-root lsp-pyright-multi-root
  :priority 2
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      ;; we send empty settings initially, LSP server will ask for the
                      ;; configuration of each workspace folder later separately
                      (lsp--set-configuration
                       (make-hash-table :test 'equal))))
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (lsp-package-ensure 'pyright callback error-callback))
  :notification-handlers (lsp-ht ((concat lsp-pyright-langserver-command "/beginProgress") 'lsp-pyright--begin-progress-callback)
                                 ((concat lsp-pyright-langserver-command "/reportProgress") 'lsp-pyright--report-progress-callback)
                                 ((concat lsp-pyright-langserver-command "/endProgress") 'lsp-pyright--end-progress-callback))))

(lsp-register-client
 (make-lsp-client
  :new-connection
  (lsp-tramp-connection (lambda ()
                          (cons (executable-find (concat lsp-pyright-langserver-command "-langserver") t)
                                lsp-pyright-langserver-command-args)))
  :major-modes '(python-mode python-ts-mode)
  :server-id 'pyright-remote
  :multi-root lsp-pyright-multi-root
  :remote? t
  :priority 1
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      ;; we send empty settings initially, LSP server will ask for the
                      ;; configuration of each workspace folder later separately
                      (lsp--set-configuration
                       (make-hash-table :test 'equal))))
  :notification-handlers (lsp-ht ((concat lsp-pyright-langserver-command "/beginProgress") 'lsp-pyright--begin-progress-callback)
                                 ((concat lsp-pyright-langserver-command "/reportProgress") 'lsp-pyright--report-progress-callback)
                                 ((concat lsp-pyright-langserver-command "/endProgress") 'lsp-pyright--end-progress-callback))))

(provide 'lsp-pyright)
;;; lsp-pyright.el ends here
