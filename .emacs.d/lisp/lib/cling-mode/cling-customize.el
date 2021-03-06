;;; cling-customize.el --- Customization settings -*- lexical-binding: t -*-

;; Copyright (c) 2014 Chris Done. All rights reserved.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(require 'cl-lib)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customization variables

(defcustom cling-process-load-or-reload-prompt nil
  "Nil means there will be no prompts on starting REPL. Defaults will be accepted."
  :type 'boolean
  :group 'cling-interactive)

;;;###autoload
(defgroup cling nil
  "Major mode for editing Cling programs."
  :link '(custom-manual "(cling-mode)")
  :group 'languages
  :prefix "cling-")

(defvar cling-mode-pkg-base-dir (file-name-directory load-file-name)
  "Package base directory of installed `cling-mode'.
Used for locating additional package data files.")

(defcustom cling-completing-read-function 'ido-completing-read
  "Default function to use for completion."
  :group 'cling
  :type '(choice
          (function-item :tag "ido" :value ido-completing-read)
          (function-item :tag "helm" :value helm--completing-read-default)
          (function-item :tag "completing-read" :value completing-read)
          (function :tag "Custom function")))

(defcustom cling-process-type
  'auto
  "The inferior Cling process type to use.

When set to 'auto (the default), the directory contents and
available programs will be used to make a best guess at the
process type:

If the project directory or one of its parents contains a
\"cabal.sandbox.config\" file, then cabal-repl will be used.

If there's a \"stack.yaml\" file and the \"stack\" executable can
be located, then stack-ghci will be used.

Otherwise if there's a *.cabal file, cabal-repl will be used.

If none of the above apply, ghci will be used."
  :type '(choice (const auto) (const ghci) (const cabal-repl) (const stack-ghci))
  :group 'cling-interactive)

(defcustom cling-process-wrapper-function
  #'identity
  "Wrap or transform cling process commands using this function.

Can be set to a custom function which takes a list of arguments
and returns a possibly-modified list.

The following example function arranges for all cling process
commands to be started in the current nix-shell environment:

  (lambda (argv) (append (list \"nix-shell\" \"-I\" \".\" \"--command\" )
                    (list (mapconcat 'identity argv \" \"))))

See Info Node `(emacs)Directory Variables' for a way to set this option on
a per-project basis."
  :group 'cling-interactive
  :type '(choice
          (function-item :tag "None" :value identity)
          (function :tag "Custom function"))
  :safe 'functionp)

(defcustom cling-ask-also-kill-buffers
  t
  "Ask whether to kill all associated buffers when a session
 process is killed."
  :type 'boolean
  :group 'cling-interactive)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Configuration

(defcustom cling-doc-prettify-types t
  "Replace some parts of types with Unicode characters like \"∷\"
when showing type information about symbols."
  :group 'cling-doc
  :type 'boolean
  :safe 'booleanp)

(defvar cling-process-ended-functions (list 'cling-process-prompt-restart)
  "Hook for when the cling process ends.")

;;;###autoload
(defgroup cling-interactive nil
  "Settings for REPL interaction via `cling-interactive-mode'"
  :link '(custom-manual "(cling-mode)cling-interactive-mode")
  :group 'cling)

(defcustom cling-process-path-cling
  "cling"
  "The path for starting ghci.
This can either be a single string or a list of strings, where the
first elements is a string and the remaining elements are arguments,
which will be prepended to `cling-process-args-cling'."
  :group 'cling-interactive
  :type '(choice string (repeat string)))


(defcustom cling-process-args-cling
  '("-std=c++17")
  "Any arguments for starting ghci."
  :group 'cling-interactive
  :type '(repeat (string :tag "Argument")))


(defcustom cling-process-do-cabal-format-string
  ":!cd %s && %s"
  "The way to run cabal comands. It takes two arguments -- the directory and the command.
See `cling-process-do-cabal' for more details."
  :group 'cling-interactive
  :type 'string)

(defcustom cling-process-log
  t ;;nil
  "Enable debug logging to \"*cling-process-log*\" buffer."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-show-debug-tips
  t
  "Show debugging tips when starting the process."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-notify-p
  nil
  "Notify using notifications.el (if loaded)?"
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-no-warn-orphans
  t
  "Suggest adding -fno-warn-orphans pragma to file when getting orphan warnings."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-hoogle-imports
  nil
  "Suggest to add import statements using Hoogle as a backend."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-hayoo-imports
  nil
  "Suggest to add import statements using Hayoo as a backend."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-hayoo-query-url
  "http://hayoo.fh-wedel.de/json/?query=%s"
  "Query url for json hayoo results."
  :type 'string
  :group 'cling-interactive)

(defcustom cling-process-suggest-cling-docs-imports
  nil
  "Suggest to add import statements using cling-docs as a backend."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-add-package
  t
  "Suggest to add packages to your .cabal file when Cabal says it
is a member of the hidden package, blah blah."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-language-pragmas
  t
  "Suggest adding LANGUAGE pragmas recommended by GHC."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-remove-import-lines
  nil
  "Suggest removing import lines as warned by GHC."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-overloaded-strings
  t
  "Suggest adding OverloadedStrings pragma to file when getting type mismatches with [Char]."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-check-cabal-config-on-load
  t
  "Check changes cabal config on loading Cling files and
restart the GHCi process if changed.."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-prompt-restart-on-cabal-change
  t
  "Ask whether to restart the GHCi process when the Cabal file
has changed?"
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-auto-import-loaded-modules
  nil
  "Auto import the modules reported by GHC to have been loaded?"
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-reload-with-fbytecode
  nil
  "When using -fobject-code, auto reload with -fbyte-code (and
then restore the -fobject-code) so that all module info and
imports become available?"
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-use-presentation-mode
  nil
  "Use presentation mode to show things like type info instead of
  printing to the message area."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-process-suggest-restart
  t
  "Suggest restarting the process when it has died"
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-popup-errors
  t
  "Popup errors in a separate buffer."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-mode-collapse
  nil
  "Collapse printed results."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-types-for-show-ambiguous
  t
  "Show types when there's no Show instance or there's an
ambiguous class constraint."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-prompt "λ> "
  "The prompt to use."
  :type 'string
  :group 'cling-interactive)

(defcustom cling-interactive-prompt2 (replace-regexp-in-string
                                        "> $"
                                        "| "
                                        cling-interactive-prompt)
  "The multi-line prompt to use.
The default is `cling-interactive-prompt' with the last > replaced with |."
  :type 'string
  :group 'cling-interactive)

(defcustom cling-interactive-mode-eval-mode
  nil
  "Use the given mode's font-locking to render some text."
  :type '(choice function (const :tag "None" nil))
  :group 'cling-interactive)

(defcustom cling-interactive-mode-hide-multi-line-errors
  nil
  "Hide collapsible multi-line compile messages by default."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-mode-delete-superseded-errors
  t
  "Whether to delete compile messages superseded by recompile/reloads."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-mode-include-file-name
  t
  "Include the file name of the module being compiled when
printing compilation messages."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-mode-read-only
  t
  "Non-nil means most GHCi/cling-interactive-mode output is read-only.
This does not include the prompt.  Configure
`cling-interactive-prompt-read-only' to change the prompt's
read-only property."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-interactive-prompt-read-only
  cling-interactive-mode-read-only
  "Non-nil means the prompt (and prompt2) is read-only."
  :type 'boolean
  :group 'cling-interactive)

(defcustom cling-import-mapping
  '()
  "Support a mapping from module to import lines.

E.g. '((\"Data.Map\" . \"import qualified Data.Map as M
import Data.Map (Map)
\"))

This will import

import qualified Data.Map as M
import Data.Map (Map)

when Data.Map is the candidate.

"
  :type '(repeat (cons (string :tag "Module name")
                       (string :tag "Import lines")))
  :group 'cling-interactive)

(defcustom cling-language-extensions
  '()
  "Language extensions in use. Should be in format: -XFoo,
-XNoFoo etc. The idea is that various tools written with HSE (or
any cling-mode code that needs to be aware of syntactical
properties; such as an indentation mode) that don't know what
extensions to use can use this variable. Examples: hlint,
hindent, structured-cling-mode, tool-de-jour, etc.

You can set this per-project with a .dir-locals.el file, in the
same vein as `cling-indent-spaces'."
  :group 'cling
  :type '(repeat 'string))

(defcustom cling-stylish-on-save nil
  "Whether to run stylish-cling on the buffer before saving.
If this is true, `cling-add-import' will not sort or align the
imports."
  :group 'cling
  :type 'boolean)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Accessor functions

(defun cling-process-type ()
  "Return `cling-process-type', or a guess if that variable is 'auto."
  (if (eq 'auto cling-process-type)
      (cond
       ;; User has explicitly initialized this project with cabal
       ((locate-dominating-file default-directory "cabal.sandbox.config")
        'cabal-repl)
       ((and (locate-dominating-file default-directory "stack.yaml")
             (executable-find "stack"))
        'stack-ghci)
       ((locate-dominating-file
         default-directory
         (lambda (d)
           (cl-find-if (lambda (f) (string-match-p ".\\.cabal\\'" f)) (directory-files d))))
        'cabal-repl)
       (t 'ghci))
    cling-process-type))

(provide 'cling-customize)
