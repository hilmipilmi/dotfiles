;; org mode "* #" break. For or-mode sections in c comments using orgstruct-mode
;;a
;;a
;;* This is a heading
;;b
;;b
;;* #
;;c
;;c

(require 'cl-lib)

(defun modes/outline-show-children (orig-fun &rest args)
  (let (pre-outline-map-region outline-map-region)
    (let ((res)
	  (ad
	    (lambda (ad-orig-fun &rest ad-args)
	      (message "outline-show-children")
	      (apply ad-orig-fun
		     (lambda ()
		       (if (<= (funcall outline-level) level)
			   (if (looking-at (concat outline-regexp "\s*#" ))
			       (progn
				 (outline-show-heading )
				 (show-entry ))
			     (outline-show-heading))))
		     (cdr ad-args)))))
      (advice-add 'outline-map-region :around ad)
      (setq res (apply orig-fun args))
      (advice-remove 'outline-map-region      ad)
      res
      )))

(defun modes/outline-hide-sublevels (orig-fun &rest args)
  (let (pre-outline-map-region outline-map-region)
    (let ((res)
	  (ad
	    (lambda (ad-orig-fun &rest ad-args)
	      (message "outline-hide-sublevels")
	      (apply ad-orig-fun
		     (lambda ()
		       (if (<= (funcall outline-level) levels)
			   (if (looking-at (concat outline-regexp "\s*#" ))
			       (progn
				 (outline-show-heading )
				 (show-entry ))
			     (outline-show-heading))))
		     (cdr ad-args)))))
      (advice-add 'outline-map-region :around ad)
      (setq res (apply orig-fun args))
      (advice-remove 'outline-map-region      ad)
      res
      )))

(defun modes/org-cycle-internal-local (orig-fun &rest args)
  (cond
   ((not (looking-at (concat outline-regexp "\s*#" )))
    (apply orig-fun args))))

(defun modes/orgstruct-commen ()
  (orgstruct-mode)
  (advice-add 'org-cycle-internal-local :around #'modes/org-cycle-internal-local)
  (advice-add 'outline-show-children    :around #'modes/outline-show-children)
  (advice-add 'outline-hide-sublevels   :around #'modes/outline-hide-sublevels)
  )

(defun c-mode-addfuncs ()
  (ggtags-mode)
  (global-set-key (kbd "M-G")  'magit-log-buffer-file)

  (when (require 'hideshow nil t)
    (progn
      (global-set-key (kbd "M-(")  'hs-toggle-hiding)
      (global-set-key (kbd "M-)")  'hs-toggle-hiding)
      ))
  (global-set-key (kbd "M-SPC")  (lambda () (interactive) (setq write-file-functions (delete 'delete-trailing-whitespace write-file-functions ))))

  )


(add-hook 'c++-mode-hook
	  (lambda ()
	    (progn (add-to-list 'write-file-functions 'delete-trailing-whitespace)
		   (if (eq system-type 'cygwin) ;; use helm for !=cygwin
		       (ggtags-mode))
		   (global-set-key (kbd "M-(")  'hs-hide-block)
		   (global-set-key (kbd "M-)")  'hs-show-block)
		   (global-set-key (kbd "M-M")
				   (lambda () (interactive)
				     (progn
				       (message "Prepare: helm-man-woman")
				       (when  (require 'helm-man nil t )
				     	 (call-interactively 'helm-man-woman)))))

		   (modes/orgstruct-commen)

		   ;; (hs-org/minor-mode)
		   (global-set-key (kbd "M-h")
				   (lambda () (interactive)
				     (progn
				       (message "Note: hs-org/minor-mode is not compatible with orgstruct-mode")
				       (orgstruct-mode -1)
				       (call-interactively 'hs-org/minor-mode))))
		   (global-set-key (kbd "M-H")  'orgstruct-mode)
		   (c-mode-addfuncs)
		   )))

(add-hook 'c-mode-hook
	  (lambda ()
	    (progn

	      (add-to-list 'write-file-functions 'delete-trailing-whitespace)
	      (if (eq system-type 'cygwin) ;; use helm for !=cygwin
		  (ggtags-mode))

	      ;;(hs-org/minor-mode)
	      (global-set-key (kbd "M-h")
			      (lambda () (interactive)
				(progn
				  (message "Note: hs-org/minor-mode is not compatible with orgstruct-mode")
				  (orgstruct-mode -1)
				  (call-interactively 'hs-org/minor-mode))))
	      ;;(global-set-key (kbd "M-h")  'hs-org/minor-mode)
	      (global-set-key (kbd "M-H")  'orgstruct-mode)
	      (global-set-key (kbd "M-M")  'helm-man-women)

	      (modes/orgstruct-commen)
	      (c-mode-addfuncs)

	      )))



(provide 'modes/c-mode.el)
