(defun apps/sh-mode-hook ()
  "Initialize mode for shell script editing."
  (setq-default
   ;; Indent with four spaces.
   sh-basic-offset 4
   sh-indentation 4))


(defun apps/shell-mode-common-hook ()
  "Shell mode common hook."
  (with-feature 'ansi-color
    ;; Enable ANSI colors for comint.
    (add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)))

(defun apps/eshell-mode-hook ()
  "Mode hook for eshell."
  (apps/shell-mode-common-hook)

  (turn-on-eldoc-mode)

  ;; Use auto-complete for completion.
  ;;(add-ac-sources 'ac-source-pcomplete)

  )

(defun apps/raise-eshell ()
  "Start, or switch to, `eshell' in the current working directory."
  (interactive)
  (let ((path (file-name-directory
               (or (buffer-file-name) *user-home-directory*)))
        (hasfile (not (eq (buffer-file-name) nil))))
    (eshell)
    (if (and hasfile (eq eshell-process-list nil))
        (progn
          (eshell/cd path)
          (eshell-reset)))))


(defun apps/shell-prompt ()
  "Return a prompt for the shell."

  (defmacro with-face (str &rest properties)
    "Print STR using PROPERTIES."
    `(propertize ,str 'face (list ,@properties)))

  (defun apps/shorten-path (path)
    "Shorten the length of PATH."
    (let ((scount (1- (count ?/ path))))
      (dotimes (i scount)
	(string-match "\\(/\\.?.\\)[^/]+" path)
	(setq path (replace-match "\\1" nil nil path))))
    path)

  (concat
   (with-face (concat (apps/shorten-path (eshell/pwd)) " ")
              :inherit 'header-line)
   (with-face (format-time-string "(%Y-%m-%d %H:%M) " (current-time))
              :inherit 'header-line)
   (with-face
    (or (ignore-errors
          (format "(%s)" (vc-responsible-backend default-directory))) "")
    :inherit 'header-line)
   (with-face "\n" :inherit 'header-line)
   (with-face user-login-name :foreground "blue")
   "@"
   (with-face "localhost" :foreground "green")
   (if (= (user-uid) 0)
       (with-face " #" :foreground "red")
     " $")
   " "))

(defun apps/eshell-init ()
  "Initialize the Emacs shell."
  (message (format "[*] %s eshell init" (timestamp_str)))
  (setq-default
   ;; Set the path to the shell cache store.
   eshell-directory-name *shell-cache-directory*
   ;; And the shell login script.
   eshell-login-script (path-join *user-home-directory* ".eshellrc")
   ;; Set eshell prompt.
   eshell-prompt-function 'apps/shell-prompt
   eshell-highlight-prompt nil
   eshell-prompt-regexp "^[^#$\n]*[#$] "
   ;; Set a decent history size.
   eshell-history-size 10000
   eshell-save-history-on-exit t
   ;; Announce the terminal type.
   eshell-term-name "eterm-color"
   ;; Allow using buffer names directly in redirection.
   eshell-buffer-shorthand t)

  (defun add-many-to-list (the-list &rest entries)
    "Add to THE-LIST any specified ENTRIES."
    (dolist (entry entries)
      (add-to-list the-list entry))
    (eval the-list))

  (after-load 'esh-module
    (add-many-to-list 'eshell-modules-list
                      ;; Rebind keys while point is in a region of input text.
                      'eshell-rebind
                      ;; Smart command output management.
                      'eshell-smart
                      ;; Extra alias functions.
                      'eshell-xtra))

  (after-load 'em-term
    ;; Commands that should be run using term for better handling of ANSI control
    ;; codes.
    (add-many-to-list 'eshell-visual-commands
                      "htop" "perf" "ssh" "telnet" "tmux"))

  ;; For `ac-source-pcomplete'.
  ;;(add-ac-modes 'eshell-mode)

  ;;; (Hooks) ;;;
  (add-hook 'eshell-mode-hook 'apps/eshell-mode-hook)

  )

(if (not (version< emacs-version "24.3"))
    (apps/eshell-init))

(provide 'apps/eshell.el)
