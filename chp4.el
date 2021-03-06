;;; chp4.el --- exercises from chap4 -*- lexical-binding: t -*-

;; Copyright (C) Jeremy Bi

;; Author: Jeremy Bi <bixuanzju@qq.com>
;; Maintainer: Jeremy Bi <bixuanzju@qq.com>
;; Created:  21 Feb 2014
;; Keywords: convenience editing
;; URL: https://github.com/bixuanzju/emacs_repo

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(defun sicp-eval (exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((unbound? exp) (eval-make-unbound exp env))
        ((and? exp) (eval-and exp env))
        ((or? exp) (eval-or exp env))
        ((lambda? exp) (make-procedure (lambda-parameters exp)
                                  (lambda-body exp)
                                  env))
        ((begin? exp)
         (eval-sequence (begin-actions exp) env))
        ((cond? exp) (sicp-eval (cond->if exp) env))
        ((let? exp) (sicp-eval (let->combination exp) env))
        ((let*? exp) (sicp-eval (let*->nexeted-lets exp) env))
        ((letrec? exp) (sicp-eval (letrec->let exp) env))
        ((for? exp) (sicp-eval (for->let exp) env))
        ((while? exp) (sicp-eval (while->let exp) env))
        ((application? exp)
         (sicp-apply (sicp-eval (operator exp) env)
                     (list-of-values (operands exp) env)))
        (t (error "Unknown expression type"))))

(defun sicp-apply (procedure arguments)
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
         (eval-sequence
          (procedure-body procedure)
          (extend-environment
           (procedure-parameters procedure)
           arguments
           (procedure-environment procedure))))
        (t
         (error "Unknown procedure type"))))

(defun list-of-values (exps env)
  (if (no-operands? exps)
      '()
    (cons (sicp-eval (first-operand exps) env)
          (list-of-values (rest-operands exps) env))))

(defun eval-if (exp env)
  (if (true? (sicp-eval (if-predicate exp) env))
      (sicp-eval (if-consequence exp) env)
    (sicp-eval (if-alternative exp) env)))

(defun eval-sequence (exps env)
  (cond ((last-exp? exps)
         (sicp-eval (first-exp exps) env))
        (t
         (sicp-eval (first-exp exps) env)
         (eval-sequence (rest-exps exps) env))))

(defun eval-assignment (exp env)
  (set-variable-value! (assignment-variable exp)
                       (sicp-eval (assignment-value exp) env)
                       env)
  'OK)

(defun eval-definition (exp env)
  (define-variable! (definition-variable exp)
                    (sicp-eval (definition-value exp) env)
                    env)
  'OK)

;; 4.1
(defun list-of-valuesl (exps env)
  (if (no-operands? exps)
      '()
    (let ((value (sicp-eval (first-operand exps) env)))
      (cons value (list-of-valuesl (rest-operands exps) env)))))
(defun list-of-valuesr (exps env)
  (if (no-operands? exps)
      '()
    (let ((rest-values (list-of-valuesr (rest-operands exps) env)))
      (cons (sicp-eval (first-operand exps) env)
            rest-values))))


(defun self-evaluating? (exp)
  (cond ((numberp exp) t)
        ((stringp exp) t)
        (t nil)))

(defun variable? (exp)
  (symbolp exp))

(defun quoted? (exp)
  (tagged-list? exp 'quote))
(defun text-of-quotation (exp)
  (cadr exp))

(defun tagged-list? (exp tag)
  (if (consp exp)
      (eq (car exp) tag)
    nil))

(defun assignment? (exp)
  (tagged-list? exp 'set!))
(defun assignment-variable (exp)
  (cadr exp))
(defun assignment-value (exp)
  (caddr exp))

(defun definition? (exp)
  (tagged-list? exp 'define))
(defun definition-variable (exp)
  (if (symbolp (cadr exp))
      (cadr exp)
    (caadr exp)))
(defun definition-value (exp)
  (if (symbolp (cadr exp))
      (caddr exp)
    (make-lambda (cdadr exp)
            (cddr exp))))

(defun lambda? (exp)
  (tagged-list? exp 'lambda))
(defun lambda-parameters (exp)
  (cadr exp))
(defun lambda-body (exp)
  (cddr exp))

(defun make-lambda (parameters body)
  (cons 'lambda (cons parameters body)))

(defun if? (exp)
  (tagged-list? exp 'if))
(defun if-predicate (exp)
  (cadr exp))
(defun if-consequence (exp)
  (caddr exp))
(defun if-alternative (exp)
  (if (not (null (cdddr exp)))
      (cadddr exp)
    'false))

(defun make-if (predicate consequence alternative)
  (list 'if predicate consequence alternative))

(defun begin? (exp)
  (tagged-list? exp 'begin))
(defun begin-actions (exp) (cdr exp))
(defun last-exp? (seq) (null (cdr seq)))
(defun first-exp (seq) (car seq))
(defun rest-exps (seq) (cdr seq))

(defun sequence->exp (seq)
  (cond ((null seq) seq)
        ((last-exp? seq) (first-exp seq))
        (t (make-begin seq))))
(defun make-begin (seq)
  (cons 'begin seq))

(defun application? (exp) (consp exp))
(defun operator (exp) (car exp))
(defun operands (exp) (cdr exp))
(defun no-operands? (ops) (null ops))
(defun first-operand (ops) (car ops))
(defun rest-operands (ops) (cdr ops))



(defun cond? (exp) (tagged-list? exp 'cond))
(defun cond-clauses (exp) (cdr exp))
(defun cond-else-clause? (clause)
  (eq (cond-predicate clause) 'else))
(defun cond-predicate (clause) (car clause))
(defun cond-actions (clause) (cdr clause))
(defun cond->if (exp) (expand-clauses (cond-clauses exp)))
;; 4.5
(defun expand-clauses (clauses)
  (if (null clauses)
      'false
    (let ((first (car clauses))
          (rest (cdr clauses)))
      (if (cond-else-clause? first)
          (if (null rest)
              (sequence->exp (cond-actions first))
            (error "ELSE clause isn't last"))
        (make-if (cond-predicate first)
                 (if (eq (car (cond-actions first)) '=>)
                     (make-application (cadr (cond-actions first))
                                       (list (cond-predicate first)))
                   (sequence->exp (cond-actions first)))
                 (expand-clauses rest))))))
(defun make-application (operator operands)
  (cons operator operands))

;; 4.4
(defun eval-and (exp env)
  (let ((clauses (and-clauses exp)))
    (eval-and-clauses clauses env)))

(defun eval-and-clauses (clauses env)
  (cond ((null clauses)
         t)
        ((last-clause? clauses)
         (if (true? (sicp-eval (car clauses) env))
             t
           nil))
        (t
         (let ((first (car clauses))
               (rest (cdr clauses)))
           (if (true? (sicp-eval first env))
               (eval-and-clauses rest env)
          nil)))))

(defun and? (exp) (tagged-list? exp 'and))
(defun and-clauses (exp) (cdr exp))
(defun last-clause? (clauses) (null (cdr clauses)))

(defun eval-or (exp env)
  (let ((clauses (or-clauses exp)))
    (eval-or-clauses clauses env)))

(defun eval-or-clauses (clauses env)
  (cond ((null clauses)
         nil)
        ((last-clause? clauses)
         (if (true? (sicp-eval (car clauses) env))
             t
           nil))
        (t
         (let ((first (car clauses))
               (rest (cdr clauses)))
           (if (true? (sicp-eval first env))
              t
             (eval-or-clauses rest env))))))

(defun or? (exp) (tagged-list? exp 'or))
(defun or-clauses (exp) (cdr exp))


(defun eval-and2 (exp env)
  (sicp-eval (expand-and-clauses (and-clauses exp)) env))
(defun expand-and-clauses (clauses)
  (cond ((null clauses)
         'true)
        ((last-clause? clauses)
         (make-if (car clauses)
                  'true
                  'false))
        (t
         (make-if (car clauses)
                  (expand-and-clauses (cdr clauses))
                  'false))))
(defun eval-or2 (exp env)
  (sicp-eval (expand-or-clauses (or-clauses exp)) env))
(defun expand-or-clauses (clauses)
  (cond ((null clauses)
         'false)
        ((last-clause? clauses)
         (make-if (car clauses)
                  'true
                  'false))
        (t
         (make-if (car clauses)
                  'true
                  (expand-or-clauses (cdr clauses))))))

;; 4.6 4.8
(defun let? (exp)
  (tagged-list? exp 'let))
(defun let-vars (exp)
  (if (null (cadr exp))
      '()
    (let ((bindings (cadr exp)))
      (mapcar (lambda (pair) (car pair)) bindings))))
(defun let-exps (exp)
  (if (null (cadr exp))
      '()
    (let ((bindings (cadr exp)))
      (mapcar (lambda (pair) (cadr pair)) bindings))))
(defun let-body (exp) (cddr exp))
(defun define-procedure (name paras body)
  (list 'define name (make-lambda paras body)))
(defun make-let-exp (bindings body)
  (cons 'let (cons bindings body)))

(defun let->combination (exp)
  (if (or (consp (cadr exp))
          (null (cadr exp)))
      (cons (make-lambda (let-vars exp) (let-body exp))
            (let-exps exp))
    ;; named let
    (let ((bindings (caddr exp))
          (procedure-name (cadr exp))
          (paramters (let-vars (cdr exp)))
          (procedure-body (let-body (cdr exp))))
      (make-let-exp bindings
                    (list (define-procedure procedure-name
                            paramters
                            procedure-body)
                          (cons procedure-name paramters))))))

;; TEST
;; (let->combination '(let ((x 3)
;;                          (y 4))
;;                      (+ x y)
;;                      (* x y)))
;; (let->combination '(let fib-iter ((a 1)
;;                                   (b 0)
;;                                   (count n))
;;                         (if (= count 0)
;;                             b
;;                           (fib-iter (+ a b) a (- count 1)))))

;; 4.7
(defun let*? (exp)
  (tagged-list? exp 'let*))
(defun let*-bindings (exp) (cadr exp))
(defun let*-body (exp) (cddr exp))
(defun make-let*-exp (bindings body)
  (cons 'let* (cons bindings body)))
(defun let*->nexeted-lets (exp)
  (let ((bindings (let*-bindings exp)))
    (if (null (cdr bindings))
        (make-let-exp bindings (let*-body exp))
      (make-let-exp
       (list (car bindings))
       (list (let*->nexeted-lets (make-let*-exp (cdr bindings) (let*-body exp))))))))

;; TEST
;; (let*->nexeted-lets '(let* ((x 3)
;;                             (y (+ x 2))
;;                             (z (+ x y 5)))
;;                        (+ x z)
;;                        (* x z)))

;; 4.9
(defun for? (exp)
  (tagged-list? exp 'for))
(defun for->let (exp)
  (let ((var (cadr exp))
        (from (caddr exp))
        (to (cadddr exp))
        (body (cddddr exp)))
    `(let for-iter ((,var ,from))
          (if (> ,var ,to)
              'Done
            (begin
             ,@body
             (for-iter (add 1 ,var)))))))

;; Example
;; (for->let '(for i 1 10 (message i) (message (+ 1 i)))) =>
;; (let for-iter ((i 1))
;;      (if (> i 10)
;;          (quote Done)
;;        (begin (message i)
;;               (message (+ 1 i))
;;               (for-iter (+ 1 i)))))

(defun while? (exp)
  (tagged-list? exp 'while))
(defun while->let (exp)
  (let ((test (cadr exp))
        (body (cddr exp)))
    `(let while-iter ()
          (if ,test
            (begin
             ,@body
             (while-iter))
              'Done))))

;; Example
;; (while->let '(while (< i 10) (message i) (set! i (+ 1 i)))) =>
;; (let while-iter nil (if (< i 10)
;;                         (begin (message i)
;;                                (set! i (+ 1 i))
;;                                (while-iter))
;;                       (quote Done)))

(defun true? (x) (not (eq x nil)))
(defun false? (x) (eq x nil))

(defun make-procedure (parameters body env)
  (list 'procedure parameters (scan-out-defines body) env))
(defun compound-procedure? (p)
  (tagged-list? p 'procedure))
(defun procedure-parameters (p) (cadr p))
(defun procedure-body (p) (caddr p))
(defun procedure-environment (p) (cadddr p))

(defun enclosing-environment (env) (cdr env))
(defun first-frame (env) (car env))
(defconst the-empty-environment '())

(defun anew-frame (variables values)
  (cons variables values))
(defun frame-variable (frame) (car frame))
(defun frame-values (frame) (cdr frame))
(defun add-binding-to-frame (var val frame)
  (setcar frame (cons var (car frame)))
  (setcdr frame (cons val (cdr frame))))

(defun extend-environment (vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (anew-frame vars vals) base-env)
    (if (< (length vars) (length vals))
        (error "Too many arguments supplied")
      (error "Too few arguments supplied"))))

;; 4.12
(defun scan-frame (var vars vals)
  (cond ((null vars)
         nil)
        ((eq var (car vars))
         vals)
        (t (scan-frame var (cdr vars) (cdr vals)))))

(defun traverse-env (var env)
  (if (null env)
      nil
    (let* ((frame (first-frame env))
           (vals (scan-frame var
                             (frame-variable frame)
                             (frame-values frame))))
      (if vals vals
        (traverse-env var (enclosing-environment env))))))

;; 4.16
(defun lookup-variable-value (var env)
  (let ((vals (traverse-env var env)))
    (if (and vals (not (eq (car vals) '*unassigned*)))
        (car vals)
      (error "Unbound variable: %s" var))))

(defun my-filter (func seq)
  (cond ((null seq) '())
        ((funcall func (car seq))
         (cons (car seq) (my-filter func (cdr seq))))
        (t (my-filter func (cdr seq)))))

(defun map-extend (op &rest ls)
  (if (null (car ls))
      '()
    (cons (apply op (mapcar #'car ls))
          (apply 'map-extend op (mapcar #'cdr ls)))))

(defun scan-out-defines (body)
  (let* ((all-defines (my-filter #'definition? body))
         (none-defines (my-filter (lambda (x) (not (definition? x)))
                                  body))
         (vars (mapcar #'definition-variable all-defines))
         (vals (mapcar #'definition-value all-defines))
         (new-body (append (map-extend (lambda (var val)
                                         (list 'set! var val))
                                       vars vals)
                           none-defines))
         (bindings (mapcar (lambda (var) `(,var '*unassigned*))
                           vars)))
    (if (null all-defines)
        body
      (list (make-let-exp bindings new-body)))))

(defun set-variable-value! (var val env)
  (let ((vals (traverse-env var env)))
    (if vals
        (setcar vals val)
      (error "Unbound variable: %s" var))))

(defun define-variable! (var val env)
  (let* ((frame (first-frame env))
         (vals (scan-frame var
                           (frame-variable frame)
                           (frame-values frame))))
    (if vals
        (setcar vals val)
      (add-binding-to-frame var val frame))))

;; 4.13
(defun unbound? (exp)
  (tagged-list? exp 'make-unbound!))
(defun delete-var-val (var vars vals)
  (cond ((null vars) (cons nil nil))
        ((eq (car vars) var)
         (cons (cdr vars) (cdr vals)))
        (t
         (let ((result (delete-var-val var (cdr vars) (cdr vals))))
           (cons (cons (car vars) (car result))
                 (cons (car vals) (cdr result)))))))

(defun eval-make-unbound (exp env)
  (let* ((sym (cadr exp))
         (frame (first-frame env))
         (vars (frame-variable frame))
         (vals (frame-values frame))
         (result (delete-var-val sym vars vals)))
    (setcar frame (car result))
    (setcdr frame (cdr result)))
  'OK)


(defun setup-environment ()
  (let ((initial-env
         (extend-environment (primitive-procedure-names)
                             (primitive-procedure-objects)
                             the-empty-environment)))
    (define-variable! 'true t initial-env)
    (define-variable! 'false nil initial-env)
    initial-env))

(defun primitive-procedure? (proc)
  (tagged-list? proc 'primitive))
(defun primitive-implementation (proc) (cadr proc))

(defconst primitive-procedures
  (list (list 'car #'car)
        (list 'cdr #'cdr)
        (list 'cons #'cons)
        (list 'null? #'null)
        (list 'add #'+)
        (list 'minus #'-)
        (list 'mult #'*)
        (list 'div #'/)
        (list 'display #'message)
        (list '> #'>)
        (list '< #'<)
        (list '= #'=)
        (list '>= #'>=)))

(defun primitive-procedure-names ()
  (mapcar #'car primitive-procedures))

(defun primitive-procedure-objects ()
  (mapcar (lambda (proc) (list 'primitive (cadr proc)))
          primitive-procedures))

(defun apply-primitive-procedure (proc args)
  (apply (primitive-implementation proc)
         args))

(defconst input-prompt ";;; M-Eval input:")
(defconst output-prompt ";;; M-Eval value:")

(defun drive-loop ()
  (prompt-for-input input-prompt)
  (let* ((input (read))
         (output (sicp-eval input the-global-environment)))
    (announce-output output-prompt)
    (user-print output))
  (drive-loop))

(defun prompt-for-input (string)
  (message "\n\n%s\n" string))
(defun announce-output (string)
  (message "\n\n%s\n" string))
(defun user-print (object)
  (if (compound-procedure? object)
      (message "compound-procedure %s %s <procedure-env>"
               (procedure-parameters object)
               (procedure-body object))
    (message "%s" object)))

;; TEST
(setq the-global-environment (setup-environment))
;; (sicp-eval '(define (append x y)
;;               (if (null? x)
;;                   y
;;                 (cons (car x) (append (cdr x) y)))) the-global-environment)
;; (sicp-eval '(append '(a b c) '(d e f))
;;            the-global-environment)
;; (sicp-eval '(define (factorial n)
;;               (if (= n 1) 1
;;                 (mult (factorial (minus n 1)) n)))
;;            the-global-environment)
;; (sicp-eval '(factorial 4) the-global-environment)
;; (sicp-eval '(define (f x)
;;               (define (even? n) (if (= n 0) true (odd? (minus n 1))))
;;               (even? x)
;;               (define (odd? n) (if (= n 0) false (even? (minus n 1)))))
;;            the-global-environment)
;; (sicp-eval '(f 3) the-global-environment)

;; ——— Build letrec ——————————————————————————
;; 4.20
(defun letrec? (exp)
  (tagged-list? exp 'letrec))
(defun letrec->let (exp)
  (let* ((bindings (cadr exp))
         (body (cddr exp))
         (vars (mapcar #'car bindings))
         (vals (mapcar #'cadr bindings))
         (nbindings (mapcar (lambda (var) `(,var '*unassigned*))
                            vars))
         (nbody (append (map-extend (lambda (var val)
                                (list 'set! var val))
                                    vars vals)
                        body)))
    (make-let-exp nbindings nbody)))

;; TEST
;; (letrec->let '(letrec ((a 4)
;;                        (b 2))
;;                 (add a b))) =>
;; (let ((a (quote *unassigned*))
;;       (b (quote *unassigned*)))
;;   (set! a 4)
;;   (set! b 2)
;;   (add a b))
;; (sicp-eval '(letrec ((fact (lambda (n)
;;                              (if (= n 1) 1 (mult n (fact (minus n 1)))))))
;;               (fact 10)) the-global-environment)

;; 4.21
(sicp-eval '((lambda (n)
               ((lambda (fact) (fact fact n))
                (lambda (ft k) (if (= k 1) 1 (mult k (ft ft (minus k 1)))))))
             10) the-global-environment)
(sicp-eval '((lambda (n)
               ((lambda (fibs) (fibs fibs n))
                (lambda (ft k) (if (or (= k 0) (= k 1)) 1
                            (add (ft ft (minus k 1))
                                 (ft ft (minus k 2)))))))
             4) the-global-environment)

(sicp-eval '(define (f x)
              ((lambda (even? odd?) (even? even? odd? x))
               (lambda (ev? od? n)
                 (if (= n 0) true (od? ev? od? (minus n 1))))
               (lambda (ev? od? n)
                 (if (= n 0) false (ev? od? ev? (minus n 1))))))
           the-global-environment)

;; ——— Separate syntax analysis from evaluation ————————————————————————————————
;; 4.22
(defun analyze (exp)
  (cond
   ((self-evaluating? exp) (analyze-self-evaluating exp))
   ((quoted? exp) (analyze-quoted exp))
   ((variable? exp) (analyze-variable exp))
   ((assignment? exp) (analyze-assignment exp))
   ((definition? exp) (analyze-definition exp))
   ((if? exp) (analyze-if exp))
   ((lambda? exp) (analyze-lambda exp))
   ((let? exp) (analyze (let->combination exp)))
   ((unless? exp) (analyze (unless->if exp)))
   ((begin? exp) (analyze-sequence (begin-actions exp)))
   ((cond? exp) (analyze (cond->if exp)))
   ((application? exp) (analyze-application exp))
   (t (error "Unknown expression type"))))

(defun analyze-self-evaluating (exp)
  (lambda (env) exp))
(defun analyze-quoted (exp)
  (let ((qval (text-of-quotation exp)))
    (lambda (env) qval)))
(defun analyze-variable (exp)
  (lambda (env) (lookup-variable-value exp env)))
(defun analyze-assignment (exp)
  (let ((var (assignment-variable exp))
        (vproc (analyze (assignment-value exp))))
    (lambda (env)
      (set-variable-value! var (funcall vproc env) env)
      'OK)))
(defun analyze-definition (exp)
  (let ((var (definition-variable exp))
        (vproc (analyze (definition-value exp))))
    (lambda (env)
      (define-variable! var (funcall vproc env) env)
      'OK)))

(defun analyze-if (exp)
  (let ((pproc (analyze (if-predicate exp)))
        (cproc (analyze (if-consequence exp)))
        (aproc (analyze (if-alternative exp))))
    (lambda (env) (if (true? (funcall pproc env))
                 (funcall cproc env)
               (funcall aproc env)))))

(defun analyze-lambda (exp)
  (let ((vars (lambda-parameters exp))
        (bproc (analyze-sequence (lambda-body exp))))
    (lambda (env) (make-procedure vars bproc env))))

(defun analyze-sequence (exps)
  (letrec ((sequentially
            (lambda (proc1 proc2)
              (lambda (env) (funcall proc1 env) (funcall proc2 env))))
           (loop (lambda (first-proc rest-procs)
                   (if (null rest-procs)
                       first-proc
                     (funcall loop (funcall sequentially
                                            first-proc
                                            (car rest-procs))
                              (cdr rest-procs)))))
           (procs (mapcar #'analyze exps)))
    (if (null procs)
        (error "Empty sequence")
      (funcall loop (car procs) (cdr procs)))))

(defun analyze-application (exp)
  (let ((fproc (analyze (operator exp)))
        (aprocs (mapcar #'analyze (operands exp))))
    (lambda (env)
      (execute-application
       (funcall fproc env)
       (mapcar (lambda (aproc) (funcall aproc env))
               aprocs)))))
(defun execute-application (proc args)
  (cond ((primitive-procedure? proc)
         (apply-primitive-procedure proc args))
        ((compound-procedure? proc)
         (funcall (procedure-body proc)
                  (extend-environment
                   (procedure-parameters proc)
                   args
                   (procedure-environment proc))))
        (t (error "Unknown procedure type"))))

(defun sicp-eval2 (exp env)
  (funcall (analyze exp) env))

(sicp-eval2 '(let ((a 3) (b 4))
               (add a b)) the-global-environment)

;; ——— Lazy Evaluation built in ————————————————————————————————————————————————
;; 4.26
(defun unless? (exp)
  (tagged-list? exp 'unless))
(defun unless-condition (exp)
  (cadr exp))
(defun unless-usual (exp)
  (caddr exp))
(defun unless-excep (exp)
  (cadddr exp))

(defun unless->if (exp)
  (let ((condition (unless-condition exp))
        (usual (unless-usual exp))
        (excep (unless-excep exp)))
    `(if ,condition ,excep ,usual)))

;; Test
;; (unless->if '(unless (= n 1)
;;                         (fact (- n 1))
;;                         1))

;; (sicp-eval2 '(define (factorial n)
;;                (unless (= n 1)
;;                  (mult n (factorial (minus n 1)))
;;                  1)) the-global-environment)
;; (sicp-eval2 '(factorial 4) the-global-environment)

(defun sicp-eval3 (exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if2 exp env))
        ((unbound? exp) (eval-make-unbound exp env))
        ((and? exp) (eval-and exp env))
        ((or? exp) (eval-or exp env))
        ((lambda? exp) (make-procedure (lambda-parameters exp)
                                  (lambda-body exp)
                                  env))
        ((begin? exp)
         (eval-sequence (begin-actions exp) env))
        ((cond? exp) (sicp-eval (cond->if exp) env))
        ((let? exp) (sicp-eval (let->combination exp) env))
        ((let*? exp) (sicp-eval (let*->nexeted-lets exp) env))
        ((letrec? exp) (sicp-eval (letrec->let exp) env))
        ((for? exp) (sicp-eval (for->let exp) env))
        ((while? exp) (sicp-eval (while->let exp) env))
        ((application? exp)
         (sicp-apply2 (actual-value (operator exp) env)
                     (operands exp)
                     env))
        (t (error "Unknown expression type"))))

(defun actual-value (exp env)
  (force-it (sicp-eval3 exp env)))

(defun sicp-apply2 (procedure arguments env)
  (cond
   ((primitive-procedure? procedure)
    (apply-primitive-procedure
     procedure
     (list-of-arg-values arguments env)))
   ((compound-procedure? procedure)
    (eval-sequence2
     (procedure-body procedure)
     (extend-environment
      (procedure-parameters procedure)
      (list-of-delayed-args arguments env)
      (procedure-environment procedure))))
   (t (error "Unknown procedure type"))))

(defun eval-sequence2 (exps env)
  (cond ((last-exp? exps)
         (sicp-eval3 (first-exp exps) env))
        (t
         (sicp-eval3 (first-exp exps) env)
         (eval-sequence2 (rest-exps exps) env))))

(defun list-of-arg-values (exps env)
  (if (no-operands? exps)
      '()
    (cons (actual-value (first-operand exps)
                        env)
          (list-of-arg-values (rest-operands exps)
                              env))))

(defun list-of-delayed-args (exps env)
  (if (no-operands? exps)
      '()
    (cons (delay-it (first-operand exps)
                    env)
          (list-of-delayed-args (rest-operands exps)
                                env))))

(defun eval-if2 (exp env)
  (if (true? (actual-value (if-predicate exp) env))
      (sicp-eval3 (if-consequence exp) env)
    (sicp-eval3 (if-alternative exp) env)))

(defun delay-it (exp env)
  (list 'thunk exp env))
(defun thunk? (obj)
  (tagged-list? obj 'thunk))
(defun thunk-exp (thunk)
  (cadr thunk))
(defun thunk-env (thunk)
  (caddr thunk))

(defun evaluated-thunk? (obj)
  (tagged-list? obj 'evaluated-thunk))
(defun thunk-value (evaluated-thunk)
  (cadr evaluated-thunk))
(defun force-it (obj)
  (cond ((thunk? obj)
         (let ((result (actual-value (thunk-exp obj)
                                     (thunk-env obj))))
           (setcar obj 'evaluated-thunk)
           (setcar (cdr obj) result)
           (setcdr (cdr obj) nil)
           result))
        ((evaluated-thunk? obj)
         (thunk-value obj))
        (t obj)))

;; 4.27
;; (sicp-eval3 '(define count 0) the-global-environment)
;; (sicp-eval3 '(define (id x) (set! count (add count 1) x)) the-global-environment)
;; (sicp-eval3 '(define w (id (id 10))) the-global-environment)
;; (sicp-eval3 'count the-global-environment)
;; (sicp-eval3 'w the-global-environment)
;; (sicp-eval3 'count the-global-environment)




;; local Variables:
;; flycheck-disabled-checkers: (emacs-lisp-checkdoc)
;; outline-regexp: ";; ———"
;; End:

;;; chp4.el ends here
