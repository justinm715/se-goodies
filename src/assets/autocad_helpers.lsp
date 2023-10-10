; In AutoCAD, use APPLOAD to load the script file, then type the command name (for example LISTANDSAVEPOINTSTOCSV)

; ListAndSavePointsToCSV
; 
; Lists the X and Y coordinates of selected points in AutoCAD.
; Select a bunch of points in AutoCAD first
;
(defun c:ListAndSavePointsToCSV ()
  (setq sel (ssget "_X" '((0 . "POINT"))))
  (if sel
    (progn
      (setq n (sslength sel))
      (setq i 0)
      (setq pointList '()) ; Initialize an empty list to store point data
      
      ; Iterate through selected points and store coordinates in the pointList
      (while (< i n)
        (setq ent (ssname sel i))
        (setq pt (cdr (assoc 10 (entget ent))))
        (setq x (car pt))
        (setq y (cadr pt))
        (setq pointList (cons (list x y) pointList))
        (setq i (1+ i))
      )
      
      ; Display point coordinates
      (setq csvData "")
      (setq i 0)
      (while (< i n)
        (setq x (car (nth i pointList)))
        (setq y (cadr (nth i pointList)))
        (setq csvData (strcat csvData (rtos x 2 6) "," (rtos y 2 6) "\n"))
        (setq i (1+ i))
      )
      (princ csvData)
      
      ; Ask to save to a CSV file
      (setq file (getfiled "Save Points As CSV" "" "csv" 1))
      (if file
        (progn
          (setq f (open file "w"))
          (if f
            (progn
              (write-line "X,Y" f) ; Add a header row to the CSV
              (write-line csvData f) ; Write point data to the CSV
              (close f)
              (princ (strcat "Points saved to " file))
            )
          )
        )
      )
    )
    (princ "No points selected.")
  )
  (princ)
)

; CreateTextForPoints
; 
; Displays the X and Y coordinates of selected points
; Select a bunch of points in AutoCAD first
;
(defun c:CreateTextForPoints ()
  (setq sel (ssget))
  (if sel
    (progn
      (setq n (sslength sel))
      (setq i 0)
      (while (< i n)
        (setq ent (ssname sel i))
        (if (= (cdr (assoc 0 (entget ent))) "POINT")
          (progn
            (setq pt (cdr (assoc 10 (entget ent))))
            (setq x (car pt))
            (setq y (cadr pt))
            
            ; Calculate the position for the text box
            (setq textX (+ x 6.0)) ; 6 inches right of the point
            (setq textY (+ y 6.0)) ; 6 inches up from the point
            
            ; Create a text entity with the coordinates
            (command "-text" (strcat (rtos textX 2 6) "," (rtos textY 2 6)) "4" "0" (strcat (rtos x 2 6) "," (rtos y 2 6)))
          )
        )
        (setq i (1+ i))
      )
    )
    (princ "No points selected.")
  )
  (princ)
)


; CreateIntersectionPoints
;
; Finds intersections of lines and creates points at those intersections.
; Note that this creates points at intersections for each pair of lines.
; If there are 3 lines intersecting at one point, there will be 3 points made.
; Post-processing is needed to remove duplicate points but my lisp game
; is not strong enough.
;
(defun c:CreateIntersectionPoints ()
    (setq ss (ssget '((0 . "LINE")))) ; select only lines
    (setq num-ents (sslength ss))
    (if (= num-ents 0) ; if no lines were selected
        (princ "No lines were selected.") ; print a message
        (progn ; if lines were selected
            (setq points '()) ; initialize the list of points
            (setq i 0)
            (repeat num-ents
                (setq ent (ssname ss i))
                (setq data (entget ent))
                (setq start (cdr (assoc 10 data)))
                (setq end (cdr (assoc 11 data)))
                (setq j 0)
                (repeat num-ents
                    (setq ent2 (ssname ss j))
                    (if (= i j) ; if the lines are the same
                        (setq j (+ j 1)) ; skip the intersection
                        (progn
                            (setq data2 (entget ent2))
                            (setq start2 (cdr (assoc 10 data2)))
                            (setq end2 (cdr (assoc 11 data2)))
                            (setq int (inters start end start2 end2)) ; get the intersection point
                            (if (and int (not (member int points))) ; if there is an intersection and the point is not already created
                                (progn
                                    (setq points (cons int points)) ; add the point to the list
                                    (command "._point" int) ; create a point at the intersection
                                )
                            )
                            (setq j (+ j 1))
                        )
                    )
                )
                (setq i (+ i 1))
            )
        )
    )
)

;; (defun c:clean_points ()
;;     (setq ss (ssget '((0 . "POINT")))) ; select only points
;;     (setq num-ents (sslength ss))
;;     (setq points '()) ; initialize the list of unique points
;;     (setq i 0)
;;     (repeat num-ents
;;         (setq ent (ssname ss i))
;;         (setq data (entget ent))
;;         (setq x (cdr (assoc 10 data)))
;;         (setq y (cdr (assoc 20 data)))
;;         (if (not (member (list x y) points)) ; if the coordinates are not already in the list
;;             (setq points (cons (list x y) points)) ; add the coordinates to the list
;;         )
;;         (setq i (+ i 1))
;;     )
;;     (command "erase" ss "") ; delete all the selected points
;;     (setq i 0)
;;     (repeat (length points) ; iterate through the list of unique coordinates
;;         (setq x (car (nth i points))) ; get the x coordinate
;;         (setq y (cadr (nth i points))) ; get the y coordinate
;;         (command "._point" x y) ; create a point at the coordinate
;;         (setq i (+ i 1))
;;     )
;; )

;; (defun c:count_lines_and_xlines ()
;;     (setq ss (ssget))
;;     (setq line-count 0 xline-count 0)
;;     (setq num-ents (sslength ss))
;;     (repeat num-ents
;;         (setq ent (ssname ss 0))
;;         (setq data (entget ent))
;;         (setq type (cdr (assoc 0 data))) ; get the entity type
;;         (if (= type "LINE")
;;             (setq line-count (+ line-count 1))
;;         )
;;         (if (= type "XLINE")
;;             (setq xline-count (+ xline-count 1))
;;         )
;;     )
;;     (princ (strcat "Number of lines: " (itoa line-count)))
;;     (princ (strcat "Number of xlines: " (itoa xline-count)))
;; )


;; (defun c:color_lines_yellow ()
;;     (setq ss (ssget '((-4 . "<OR") (0 . "LINE") (0 . "XLINE") (-4 . "OR>")))) ; select either lines or xlines
;;     (setq num-ents (sslength ss))
;;     (setq i 0)
;;     (repeat num-ents
;;         (setq ent (ssname ss i))
;;         (setq data (entget ent))
;;         (if (assoc 62 data)
;;             (setq data (subst (cons 62 2) (assoc 62 data) data)) ; change the color if it exists
;;             (setq data (append data (list (cons 62 2)))) ; append the color if it does not exist
;;         )
;;         (princ (entmod data)) ; update the entity and print the return value
;;         (setq i (+ i 1))
;;     )
;; )

(defun c:ExtractCoords ()
  (setq sel (ssget '((0 . "POINT"))))
  (if sel
    (progn
      ;; (setq desktop (getvar "USERPROFILE"))
      ;; (if (and desktop (/= desktop ""))
        
      ;;   ; (setq fname "C:\\Coords.txt") ; Default path if USERPROFILE is not available
      ;; )

      (setq fname "C:/Users/justin/OneDrive/Desktop/dev/temp.txt")

      ; Try to open the file and check if it's successful
      (setq f (open fname "w"))
      (if f ; If f is not nil, meaning file opened successfully
        (progn
          (setq num-objs (sslength sel))
          (setq index 0)
          (repeat num-objs
            (setq ent (ssname sel index))
            (if ent
              (progn
                (setq pt (cdr (assoc 10 (entget ent))))
                (if pt
                  (progn
                    (setq x (car pt))
                    (setq y (cadr pt))
                    ; Insert x y coordinates with a tab in between
                    (write-line (strcat (rtos x) "\t" (rtos y)) f)
                  )
                )
              )
            )
            (setq index (+ index 1)) ; Increment the index for the next object in the selection set
          )
          (close f)
        )
        (alert (strcat "Failed to write to file: " fname))
      )
    )
    (alert "No points selected!")
  )
)
