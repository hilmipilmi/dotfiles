;;(ttyexpect_test0)

;;(>= (+ (float-time) 0.0001) (float-time))
(defun ttyexpect-self-test0 ()
  (ttypexpect-rec 0 "Dadaism \n test\n Usermacro x/assignstr")
  (ttypexpect-rec 0 "Dadaism \n test\n Usermacro x/assignstr\nAnother")
  (let ((c (ttypexpect [ [0 "Another" FOUNDAnother ] [0 "Usermacro x/assign" FOUND ]  [ TIMEOUT ] ] 10.0 )))
    (pcase c
      ('TIMEOUT 1)
      ('FOUND 2)
      ('FOUNDAnother 3)
      ))
  )



(defun ttypexpect-hiz-run ()
  (interactive)
  (make-thread
   (lambda ()
     (progn
       (condition-case nil
	   (progn
	     (message "%d: ttypexpect-hiz-run" 0)
	     ;;(ttypexpect_sync 0)
	     ;;(ttypexpect_wait_for_console 0 "\n" "HiZ>" 1 5)
	     (ttypexpect_send 0 "\nexit\n?\n")
	     (let ((c (ttypexpect [ [0 "Usermacro x/assign" FOUND] [TIMEOUT] ] 1.0 )))
	       (pcase c
		 ('TIMEOUT (progn (message " > Timeout" )))
		 ('FOUND (progn (message " > Found Usermacro x/assign" )))
		 ))
	     (ttypexpect_wait_for_console 0 "\n" "HiZ>" 1 5))
	 (error (progn
		  (message "[-] hiz test fail")
		  (debug))))
       ))
     )
  ;;(sleep-for 10)
  )



(defun ttyexpect-detect (idx)
  (ttypexpect_sync idx)
  (ttypexpect_send idx "\nexit\n?\n")
  (catch 'found
    (progn
      (let ((c (ttypexpect [ [0 "Usermacro x/assign" FOUND] [TIMEOUT] ] 1.0 )))
	(pcase c
	  ('TIMEOUT (progn (message " > Timeout" )))
	  ('FOUND (progn
		    (message " > detect hiz on %d" idx)
		    (throw 'found "hiz")
		    ))
	  ))
      )
    (puthash found idx ttypexpect-buftype)
    ))

(provide 'ttylogtest)
