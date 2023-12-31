(defun c:FindIntersections (/ ss pt set)
  (vl-load-com)
  (setq ss (ssget '((0 . "LINE"))))
  (setq set (vlax-make-safearray vlax-vbVariant (cons 1 0)))
  (repeat (setq id1 (sslength ss))
    (setq ob1 (vlax-ename->vla-object (ssname ss (setq id1 (1- id1)))))
    (repeat (setq id2 id1)
      (setq ob2 (vlax-ename->vla-object (ssname ss (setq id2 (1- id2))))
            int (vla-intersectwith ob1 ob2 1)
            ptsa (vlax-safearray->list (vlax-variant-value int))
      )
      (while ptsa
        (setq pt (list (car ptsa) (cadr ptsa)))
        (if (not (member pt set))
          (progn
            (setq set (cons pt set))
            (command "_.POINT" pt)
          )
        )
        (setq ptsa (cdddr ptsa))
      )
    )
  )
  (princ (length set))
  (princ)
)
