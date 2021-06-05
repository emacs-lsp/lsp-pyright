;;; lsp-pyright.el --- Python LSP client using Pyright -*- lexical-binding: t; -*-

;; Copyright (C) 2020 emacs-lsp maintainers

;; Author: Arif Rezai, Vincent Zhang, Andrew Christianson
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1") (lsp-mode "7.0") (dash "2.18.0") (ht "2.0") (f "0.20.0") (s "1.12.0"))
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
(require 's)
(require 'f)

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

(defcustom lsp-pyright-use-library-code-for-types t
  "Determines whether to analyze library code.
In order to extract type information in the absence of type stub files.
This can add significant overhead and may result in
poor-quality type information.
The default value for this option is false."
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

(defcustom lsp-pyright-typechecking-mode "basic"
  "Determines the default type-checking level used by pyright.
This can be overridden in the configuration file."
  :type '(choice
          (const "off")
          (const "basic")
          (const "strict"))
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

(defcustom lsp-pyright-stub-path ""
  "Path to directory containing custom type stub files."
  :type 'directory
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

(defcustom lsp-pyright-typeshed-paths []
  "Paths to look for typeshed modules.
Pyright currently honors only the first path in the array."
  :type 'lsp-string-vector
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

(defcustom lsp-pyright-pipenv-executable-cmd nil
  "Path to the pipenv executable. Will auto detect using
`executable-find' if this is set to `nil'."
  :type 'string
  :group 'lsp-pyright)

(defcustom lsp-pyright-poetry-executable-cmd nil
  "Path to the poetry executable. Will auto detect using
`executable-find' if this is set to `nil'."
  :type 'string
  :group 'lsp-pyright)

(defcustom lsp-pyright-prefer-remote-env t
  "If non nil, lsp-pyright will perfer remote python environment.
Only available in Emacs 27 and above."
  :type 'boolean
  :group 'lsp-pyright)

(defvar lsp-pyright--project-info-cache nil
  "Used to cache results from project management tools between invocations.")

(defun lsp-pyright--locate-pipenv ()
  "Get the path of the pipenv executable. If
  `lsp-pyright-pipenv-executable-cmd' is non-nil it will be
  returned. Otherwise, `exec-path' will be searched for a
  executable named pipenv"
  (or lsp-pyright-pipenv-executable-cmd
      (executable-find "pipenv")))

(defun lsp-pyright--locate-poetry ()
  "Get the path of the poetry executable. If
  `lsp-pyright-poetry-executable-cmd' is non-nil it will be
  returned. Otherwise, `exec-path' will be searched for a
  executable named poetry"
  (or lsp-pyright-poetry-executable-cmd
      (executable-find "poetry")))

(defun lsp-pyright--call-process (&rest cmd)
  "Wrapper around `call-process' which executes the command and
arguments as given in CMD. Returns the output from CMD only if
CMD does not return a failure status."
  (with-temp-buffer
    (let ((return-status
           (apply #'call-process (car cmd) nil t nil (cdr cmd))))
      (when (zerop return-status)
        (s-trim (buffer-string))))))

(defun lsp-pyright--locate-project-file (f)
  "Checks if the file F exists in the current project."
  (and (lsp-workspace-root)
       (let ((projfile (f-join (lsp-workspace-root) f)))
         (f-exists? projfile))))

(defun lsp-pyright--project-is-pipenv ()
  "Checks if pipenv is used for current project."
  (and (lsp-pyright--locate-pipenv)
   (lsp-pyright--locate-project-file "Pipfile")))

(defun lsp-pyright--project-is-poetry ()
  "Checks if pipenv is used for current project."
  (and (lsp-pyright--locate-poetry)
   (lsp-pyright--locate-project-file "pyproject.toml")))

(defun lsp-pyright--project-info-from-tool (property)
  "Queries poetry or pipenv for project information and returns
either the virtualenv or the python interpreter of the project
depending on whether the value of PROPERTY is 'python or 'venv."
  (unless lsp-pyright--project-info-cache
    (setq-local
     lsp-pyright--project-info-cache
     (let ((project-info
            (cond
             ((lsp-pyright--project-is-pipenv)
              (if-let* ((pipenv (lsp-pyright--locate-pipenv))
                        (venv (lsp-pyright--call-process pipenv "--venv"))
                        (python (lsp-pyright--call-process pipenv "--py")))
                  (progn
                    (lsp-log "Detected pipenv project. Using: venv %s and python %s"
                             venv python)
                    `(:venv ,venv :python ,python))))
             ((lsp-pyright--project-is-poetry)
              (if-let* ((poetry (lsp-pyright--locate-poetry))
                        (venv (lsp-pyright--call-process poetry "env" "info" "-p"))
                        (python (f-join venv "bin" "python")))
                  (progn
                    (lsp-log "Detected poetry project. Using: venv %s and python %s"
                             venv python)
                    `(:venv ,venv :python ,python))))
             (t (lsp-log "Project is not using poetry or pipenv.")))))
       (and project-info
            (plist-get project-info :python)
            (plist-get project-info :venv)
            project-info))))
     (when lsp-pyright--project-info-cache
       (pcase property
         ('python (plist-get lsp-pyright--project-info-cache :python))
         ('venv (plist-get lsp-pyright--project-info-cache :venv)))))

(defun lsp-pyright-locate-venv ()
  "Look for virtual environments local to the workspace."
  (or lsp-pyright-venv-path
      (lsp-pyright--project-info-from-tool 'venv)
      (and lsp-pyright-venv-directory
           (-when-let (venv-base-directory
                       (locate-dominating-file
                        default-directory
                        lsp-pyright-venv-directory))
             (concat venv-base-directory lsp-pyright-venv-directory)))
      (-when-let (venv-base-directory (locate-dominating-file default-directory "venv/"))
        (concat venv-base-directory "venv"))
      (-when-let (venv-base-directory (locate-dominating-file default-directory ".venv/"))
        (concat venv-base-directory ".venv"))))

(defun lsp-pyright-locate-python ()
  "Look for python executable cmd to the workspace."
  (or (lsp-pyright--project-info-from-tool 'python)
      (with-no-warnings
        (if (>= emacs-major-version 27)
            (executable-find lsp-pyright-python-executable-cmd lsp-pyright-prefer-remote-env)
          (executable-find lsp-pyright-python-executable-cmd)))))

(defun lsp-pyright--begin-progress-callback (workspace &rest _)
  "Log begin progress information.
Current LSP WORKSPACE should be passed in."
  (when lsp-progress-via-spinner
    (with-lsp-workspace workspace
      (--each (lsp--workspace-buffers workspace)
    (when (buffer-live-p it)
          (with-current-buffer it
            (lsp--spinner-start)))))
    )
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
            (lsp--spinner-stop)))))
    )
  (lsp-log "Pyright language server is analyzing...done"))

(lsp-register-custom-settings
 `(("pyright.disableLanguageServices" lsp-pyright-disable-language-services t)
   ("pyright.disableOrganizeImports" lsp-pyright-disable-organize-imports t)
   ("python.analysis.autoImportCompletions" lsp-pyright-auto-import-completions t)
   ("python.analysis.typeshedPaths" lsp-pyright-typeshed-paths)
   ("python.analysis.stubPath" lsp-pyright-stub-path)
   ("python.analysis.useLibraryCodeForTypes" lsp-pyright-use-library-code-for-types t)
   ("python.analysis.diagnosticMode" lsp-pyright-diagnostic-mode)
   ("python.analysis.typeCheckingMode" lsp-pyright-typechecking-mode)
   ("python.analysis.logLevel" lsp-pyright-log-level)
   ("python.analysis.autoSearchPaths" lsp-pyright-auto-search-paths t)
   ("python.analysis.extraPaths" lsp-pyright-extra-paths)
   ("python.pythonPath" lsp-pyright-locate-python)
   ;; We need to send empty string, otherwise  pyright-langserver fails with parse error
   ("python.venvPath" (lambda () (or (lsp-pyright-locate-venv) "")))))

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
  :initialized-fn (lambda (workspace)
                    (with-lsp-workspace workspace
                      ;; we send empty settings initially, LSP server will ask for the
                      ;; configuration of each workspace folder later separately
                      (lsp--set-configuration
                       (make-hash-table :test 'equal))))
  :download-server-fn (lambda (_client callback error-callback _update?)
                        (lsp-package-ensure 'pyright callback error-callback))
  :notification-handlers (lsp-ht ("pyright/beginProgress" 'lsp-pyright--begin-progress-callback)
                                 ("pyright/reportProgress" 'lsp-pyright--report-progress-callback)
                                 ("pyright/endProgress" 'lsp-pyright--end-progress-callback))))

(provide 'lsp-pyright)
;;; lsp-pyright.el ends here
