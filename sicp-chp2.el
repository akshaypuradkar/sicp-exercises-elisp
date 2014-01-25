;;; -*- lexical-binding: t -*-

;; 2.1
(defun make-rat (n d)
  (defun gcd (a b)
    (cond
     ((> b a) (gcd b a))
     ((= b 0) a)
     (t (gcd b (% a b)))))
  (let* ((pos-n (abs n))
         (pos-d (abs d))
         (g (gcd pos-n pos-d))
         (sign (* n d)))
    (if (< sign 0)
        (cons (- 0 (/ pos-n g)) (/ pos-d g))
      (cons (/ pos-n g) (/ pos-d g)))))

;; 2.2
(defun make-segment (p1 p2)
  (cons p1 p2))

(defun start-segment (l)
  (car l))

(defun end-segment (l)
  (cdr l))

(defun make-point (x y)
  (cons x y))

(defun x-point (p)
  (car p))

(defun y-point (p)
  (cdr p))

(defun midpoint-segment (l)
  (let ((start (start-segment l))
        (end (end-segment l)))
    (make-point (/ (+ (x-point start)
                      (x-point end))
                   2.0)
                (/ (+ (y-point start)
                      (y-point end))
                   2.0))))

(defun print-point (p)
  (message "(%f, %f)" (x-point p) (y-point p)))

;; 2.4
(defun sicp-cons (x y)
  (lambda (m) (funcall m x y)))
(defun sicp-car (z)
  (funcall z (lambda (p _) p)))
(defun sicp-cdr (z)
  (funcall z (lambda (_ q) q)))

;; 2.5
(defun cons2 (a b)
  (* (expt 2 a) (expt 3 b)))
(defun car2 (n)
  (many n 2))
(defun cdr2 (n)
  (many n 3))

(defun many (n base)
  (defun iter (n k)
    (if (= (% n base) 0)
        (iter (/ n base) (1+ k))
      k))
  (iter n 0))

;; 2.6
(defconst church-zero (lambda (_) (lambda (x) x)))
(defun add-1 (n)
  (lambda (f) (lambda (x) (funcall f (funcall (funcall n f) x)))))
(defconst church-one (lambda (f) (lambda (x) (funcall f x))))
(defconst church-two (lambda (f) (lambda (x) (funcall f (funcall f x)))))

(defun plus (n m)
  "Verify by eval `(funcall (funcall (plus church-one church-two) '1+) 0)',
   which should return 3"
  (lambda (f) (lambda (x) (funcall (funcall n f) (funcall (funcall m f) x)))))

;; 2.7
(defun make-interval (a b)
  (cons a b))

(defun lower-bound (intvl)
  (car intvl))
(defun upper-bound (intvl)
  (cdr intvl))

(defun add-interval (x y)
  (make-interval (+ (lower-bound x) (lower-bound y))
                 (+ (upper-bound x) (upper-bound y))))

(defun mul-interval (x y)
  (let ((p1 (* (lower-bound x) (lower-bound y)))
        (p2 (* (lower-bound x) (upper-bound y)))
        (p3 (* (upper-bound x) (lower-bound y)))
        (p4 (* (upper-bound x) (upper-bound y))))
    (make-interval (min p1 p2 p3 p4)
                   (max p1 p2 p3 p4))))

(defun div-interval (x y)
  (mul-interval
   x
   (make-interval (/ 1.0 (upper-bound y))
                  (/ 1.0 (lower-bound y)))))

;; 2.8
(defun sub-interval (x y)
  (add-interval x
                (make-interval (- 0 (upper-bound y))
                               (- 0 (lower-bound y)))))

;; 2.9
(defun width (x)
  (/ (- (upper-bound x) (lower-bound x)) 2.0))

;; (= (width (add-interval (make-interval 1 3) (make-interval 2 4)))
;;    (+ (width (make-interval 1 3)) (width (make-interval 2 4))))

;; (= (width (mul-interval (make-interval 1 3) (make-interval 2 4)))
;;    (* (width (make-interval 1 3)) (width (make-interval 2 4))))

;; 2.10
(defun div-interval-safe (x y)
  (if (= 0 (width y))
      (error "Divide by zero!")
    (mul-interval
     x
     (make-interval (/ 1.0 (upper-bound y))
                    (/ 1.0 (lower-bound y))))))

;; 2.12
(defun make-center-percent (c per)
  (cons (- c (* per c)) (+ c (* per c))))
(defun center (x)
  (let ((start (lower-bound x))
        (end (upper-bound x)))
    (/ (float (- end start)) (+ end start))))


;; 2.13 sum of two tolerances

;; 2.17
(defun last-pair (lst)
  (if (= (length lst) 1)
      lst
    (last-pair (cdr lst))))

;; 2.18
(defun sicp-reverse (lst)
  (defun iter (l lst)
    (if (null l)
        lst
      (iter (cdr l) (cons (car l) lst))))
  (iter lst nil))

;; 2.19
(defun even? (a)
  (= (mod a 2) 0))
(defun odd? (a)
  (/= (mod a 2) 0))

(defun same-parity (a &rest lst)
  (defun trans (l p)
    (cond
     ((null l) nil)
     ((funcall p (car l)) (cons (car l) (trans (cdr l) p)))
     (t (trans (cdr l) p))))
  (if (even? a)
      (cons a (trans lst 'even?))
    (cons a (trans lst 'odd?))))

;; 2.21
(defun map (proc items)
  (if (null items)
      nil
    (cons (funcall proc (car items)) (map proc (cdr items)))))
(defun square-list1 (items)
  (if (null items)
      nil
    (cons (* (car items) (car items)) (square-list1 (cdr items)))))
(defun square-list2 (items)
  (map (lambda (k) (* k k)) items))

;; 2.23
(defun for-each (proc lst)
  (if (null lst) t
    (funcall proc (car lst))
    (for-each proc (cdr lst))))

;; 2.27
(defun deep-reverse (tree)
  (cond
   ((null tree) tree)
   ((atom (car tree)) (append (deep-reverse (cdr tree)) (list (car tree))))
   (t (append (deep-reverse (cdr tree))
              (list (deep-reverse (car tree)))))))

;; 2.28
(defun fringe (tree)
  (cond
   ((null tree) nil)
   ((atom (car tree)) (cons (car tree) (fringe (cdr tree))))
   (t (append (fringe (car tree))
              (fringe (cdr tree))))))

;; 2.29
(defun make-mobile (left right)
  (list left right))

(defun make-branch (length structure)
  (list length structure))

(defun left-branch (m)
  (car m))
(defun right-branch (m)
  (car (cdr m)))
(defun branch-length (b)
  (car b))
(defun branch-structure (b)
  (car (cdr b)))

(defun total-weight (mobile)
  (let* ((left (left-branch mobile))
         (right (right-branch mobile))
         (ls (branch-structure left))
         (rs (branch-structure right)))
    (cond
     ((and (atom ls) (atom rs)) (+ ls rs))
     ((atom ls) (+ ls (total-weight rs)))
     ((atom rs) (+ (total-weight ls) rs))
     (t (+ (total-weight ls) (total-weight rs))))))

(defun balance? (mobile)
  (let* ((left (left-branch mobile))
         (right (right-branch mobile))
         (ls (branch-structure left))
         (ll (branch-length left))
         (rs (branch-structure right))
         (rl (branch-length right)))
    (cond
     ((and (atom ls) (atom rs)) (= (* ll ls) (* rl rs)))
     ((atom ls) (= (* rl (total-weight rs) (* ll ls))))
     ((atom rs) (= (* ll (total-weight ls) (* rl rs))))
     (t (= (* ll (total-weight ls)) (* rl (total-weight rs)))))))

;; 2.30
(defun square-tree1 (tree)
  (map (lambda (sub-tree)
         (if (atom sub-tree)
             (* sub-tree sub-tree)
           (square-tree sub-tree)))
       tree))
(defun square-tree2 (tree)
  (cond
   ((null tree) nil)
   ((atom (car tree)) (cons (* (car tree) (car tree))
                            (square-tree2 (cdr tree))))
   (t (cons (square-tree2 (car tree))
            (square-tree2 (cdr tree))))))

;; 2.31
(defun tree-map (proc tree)
  (map (lambda (sub-tree)
         (if (atom sub-tree)
             (funcall proc sub-tree)
           (tree-map proc sub-tree)))
       tree))

;; 2.32
(defun subset (s)
  (if (null s) (list nil)
    (let ((rest (subset (cdr s))))
      (append (map (lambda (sub) (cons (car s) sub)) rest) rest))))

;; 2.33
(defun filter (pred lst)
  (cond
   ((null lst) nil)
   ((funcall pred (car lst))
    (cons (car lst) (filter pred (cdr lst))))
   (t (filter pred (cdr lst)))))

(defun accumulate (op initial lst)
  (if (null lst) initial
    (funcall op (car lst) (accumulate op initial (cdr lst)))))

(defun sicp-map (p lst)
  (accumulate (lambda (x y) (cons (funcall p x) y)) nil lst))

(defun sicp-append (seq1 seq2)
  (accumulate 'cons seq2 seq1))

(defun sicp-length (lst)
  (accumulate (lambda (_ y) (1+ y)) 0 lst))

;; 2.34
(defun horner-eval (x coefficient-sequence)
  (accumulate (lambda (this-coeff higher-terms)
                (+ (* higher-terms x) this-coeff))
              0
              coefficient-sequence))

;; 2.35
(defun count-leaves1 (tr)
  (accumulate (lambda (tree leaves)
                (if (atom tree)
                    (+ 1 leaves)
                  (+ (count-leaves tree)
                     leaves)))
              0
              tr))
(defun count-leaves2 (tr)
  (accumulate '+ 0 (map (lambda (k)
                          (if (atom k) 1
                            (count-leaves2 k)))
                        tr)))

;; 2.36
(defun accumulate-n (op init seqs)
  (if (null (car seqs))
      nil
    (cons (accumulate op init (map 'car seqs))
          (accumulate-n op init (map 'cdr seqs)))))

;; 2.37
(defun map-extend (op &rest ls)
  (if (null (car ls))
      nil
    (cons (apply op (map 'car ls))
          (apply 'map-extend op (map 'cdr ls)))))

(defun dot-product (v w)
  (accumulate '+ 0 (map-extend '* v w)))

(defun matrix-*-vector (m v)
  (map (lambda (mv) (dot-product mv v)) m))

(defun transpose (mat)
  (accumulate-n 'cons nil mat))

(defun matrix-*-matrix (m n)
  (let ((cols (transpose n)))
    (map (lambda (row) (matrix-*-vector cols row)) m)))

;; 2.39
(defun fold-left (f acc l)
  (if (null l) acc
    (fold-left f (funcall f acc (car l)) (cdr l))))

(defun reverse1 (seq)
  (accumulate (lambda (x y) (append y (list x))) nil seq))
(defun reverse2 (seq)
  (fold-left (lambda (x y) (cons y x)) nil seq))

;; 2.40
(defun flatmap (proc seq)
  (accumulate 'append nil (map proc seq)))
(defun unique-pair (n)
  (flatmap (lambda (i) (map (lambda (j) (list j i))
                       (number-sequence 1 (- i 1))))
           (number-sequence 1 n)))

;; 2.41

(defun unique-triple (n)
  (filter (lambda (triple) (= (length triple)
                         (length (remove-duplicates triple))))
          (flatmap (lambda (i) (flatmap (lambda (j) (map (lambda (k) (list i j k))
                                               (number-sequence 1 n)))
                                   (number-sequence 1 n)))
                   (number-sequence 1 n))))
(defun all-triple (n s)
  (filter (lambda (triple) (= s (apply '+ triple)))
          (unique-triple n)))

;; 2.42
(defun queens (board-size)
  (defun queen-cols (k)
    (if (= k 0)
        (list nil)
      (filter
       (lambda (positions) (safe? k positions))
       (flatmap
        (lambda (rest-of-queens)
          (map (lambda (new-row)
                 (adjoin-position
                  new-row k rest-of-queens))
               (number-sequence 1 board-size)))
        (queen-cols (- k 1))))))
  (defun adjoin-position (row k q)
    (cons row q))
  (defun andall (lst)
    (if (null lst) t
      (and (car lst) (andall (cdr lst)))))
  (defun safe? (k pos)
    (let ((row (car pos))
          (col 1))
      (andall (map (lambda (pair) (and (/= row (car pair))
                                  (/= (abs (- (car pair) row))
                                      (abs (- (cdr pair) col)))))
                   (map-extend 'cons (cdr pos) (number-sequence 2 k))))))
  (queen-cols board-size))




;; Local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; End:
