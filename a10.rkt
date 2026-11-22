#lang racket
(require rackunit)

(struct const (value) #:transparent)
(struct dBvar (index) #:transparent)
(struct mult (l r) #:transparent)
(struct decr (r) #:transparent)
(struct zerop (r) #:transparent)
(struct dBlam (body) #:transparent)
(struct app (rator rand) #:transparent)
(struct dBlocal (rhs body) #:transparent)
(struct ifte (test conseq alt) #:transparent)
(struct dBcatch (body) #:transparent)
(struct throw (continuation result) #:transparent)

(struct empty-env () #:transparent)
(struct extend-env (a env) #:transparent)
(struct clos-lam (body env) #:transparent)
(struct cont-val (k) #:transparent)

(struct k-empty () #:transparent)
(struct k-multL (r env k) #:transparent)
(struct k-multR (lv k) #:transparent)
(struct k-decr (k) #:transparent)
(struct k-zerop (k) #:transparent)
(struct k-if (conseq alt env k) #:transparent)
(struct k-appR (rand env k) #:transparent)
(struct k-appA (f k) #:transparent)
(struct k-localR (body env k) #:transparent)
(struct k-throwK (result env k) #:transparent)
(struct k-throwV (cv k) #:transparent)

(define apply-env
  (lambda (env y k^)
    (match env
      [(empty-env) (error 'value-of-cps "unbound variable")]
      [(extend-env a env1)
       (if (zero? y)
           (apply-k k^ a)
           (apply-env env1 (sub1 y) k^))])))

(define apply-closure
  (lambda (cl a k^)
    (match cl
      [(clos-lam body env)
       (value-of-cps body (extend-env a env) k^)])))

(define apply-k
  (lambda (k v)
    (match k
      [(k-empty) v]
      [(k-multL r env k2) (value-of-cps r env (k-multR v k2))]
      [(k-multR lv k2) (apply-k k2 (* lv v))]
      [(k-decr k2) (apply-k k2 (sub1 v))]
      [(k-zerop k2) (apply-k k2 (zero? v))]
      [(k-if conseq alt env k2)
       (if v
           (value-of-cps conseq env k2)
           (value-of-cps alt env k2))]
      [(k-appR rand env k2) (value-of-cps rand env (k-appA v k2))]
      [(k-appA f k2) (apply-closure f v k2)]
      [(k-localR body env k2) (value-of-cps body (extend-env v env) k2)]
      [(k-throwK result env k2) (value-of-cps result env (k-throwV v k2))]
      [(k-throwV cv k2)
       (match cv
         [(cont-val kcap) (apply-k kcap v)]
         [_ (error 'value-of-cps "throw: bad continuation value")])])))

(define value-of-cps
  (lambda (e env k^)
    (match e
      [(const v) (apply-k k^ v)]
      [(mult l r) (value-of-cps l env (k-multL r env k^))]
      [(decr r) (value-of-cps r env (k-decr k^))]
      [(zerop r) (value-of-cps r env (k-zerop k^))]
      [(ifte test conseq alt) (value-of-cps test env (k-if conseq alt env k^))]
      [(dBcatch body) (value-of-cps body (extend-env (cont-val k^) env) k^)]
      [(throw continuation result) (value-of-cps continuation env (k-throwK result env k^))]
      [(dBlocal rhs body) (value-of-cps rhs env (k-localR body env k^))]
      [(dBvar y) (apply-env env y k^)]
      [(dBlam body) (apply-k k^ (clos-lam body env))]
      [(app rator rand) (value-of-cps rator env (k-appR rand env k^))])))

(define empty-k (lambda () (k-empty)))

(define last-non-zero
  (lambda (ls)
    (let/cc k^
      (letrec
          [(scan (lambda (xs)
                   (match xs
                     ['() '()]
                     [(cons 0 t) (k^ (scan t))]
                     [(cons x t) (cons x (scan t))])))]
        (scan ls)))))
