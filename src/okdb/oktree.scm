(library (okdb oktree)
  (export make-oktree
          oktree-set
          oktree-ref
          oktree->alist
          oktree-cursor-next!?
          oktree-cursor-position?
          oktree-cursor-previous!?
          oktree-cursor-seek!)

  (import (scheme base)
          (scheme fixnum))

  ;; oktree is a persistent balanced binary tree that use logarithmic
  ;; measure to (try...) to keep the tree balanced. It only support
  ;; bytevector as keys. It can only have `fx-greatest` keys in the
  ;; tree.

  ;; TODO: add reference to the paper and re-read it.

  ;; TODO: do some tests to see if it is properly balanced.

  (define (lexicographer bytevector other)
    ;; Return 'less if BYTEVECTOR is before OTHER, 'equal if equal and
    ;; otherwise 'more
    (let ((end (min (bytevector-length bytevector)
                    (bytevector-length other))))
      (let loop ((index 0))
        (if (fx=? end index)
            (if (fx= (bytevector-length bytevector)
                     (bytevector-length other))
                'equal
                (if (fx<? (bytevector-length bytevector)
                          (bytevector-length other))
                    'less
                    'more))
            (let ((delta (fx- (bytevector-u8-ref bytevector index)
                              (bytevector-u8-ref other index))))
              (if (fxzero? delta)
                  (loop (fx+ 1 index))
                  (if (fxnegative? delta)
                      'less
                      'more)))))))

  (define-record-type <oktree>
    (%make-oktree root)
    oktree?
    (root oktree-root))

  (define-record-type <node>
    (make-node key value size left right)
    node?
    (key node-key)
    (value node-value)
    (size %node-size)
    (left node-left)
    (right node-right))

  (define (node-size maybe-node)
    (if maybe-node (%node-size maybe-node) 0))

  (define (make-oktree)
    (%make-oktree #f))

  (define (oktree-empty? oktree)
    (not (oktree-root oktree)))

  (define (log2<? a b)
    ;; This procedure as the same truth table as the procedure that
    ;; compares the position of the most significant bit that is set.
    ;; A is less than B if A's most significant bit set is at a lower
    ;; position, than the most significant bit set in B.
    (and (fx<? a b) (fx<? (fxarithmetic-shift-left (fxand a b) 1) b)))

  (define (too-big? a b)
    (log2<? a (fxarithmetic-shift-right b 1)))

  (define (single-rotation? a b)
    (not (log2<? b a)))

  (define (node-join key value left right)
    (make-node key
               value
               (fx+ (node-size left)
                    (node-size right)
                    1)
               left
               right))

  (define (single-left-rotation key value left right)
    (node-join (node-key right)
               (node-value right)
               (node-join key value left (node-left right))
               (node-right right)))

  (define (double-left-rotation key value left right)
    (node-join (node-key (node-left right))
               (node-value (node-left right))
               (node-join key value left (node-left (node-left right)))
               (node-join (node-key right)
                          (node-value right)
                          (node-right (node-left right))
                          (node-right right))))

  (define (single-right-rotation key value left right)
    (node-join (node-key left)
               (node-value left)
               (node-left left)
               (node-join key value (node-right left) right)))

  (define (double-right-rotation key value left right)
    (node-join (node-key (node-right left))
               (node-value (node-right left))
               (node-join (node-key left)
                          (node-value left)
                          (node-left left)
                          (node-left (node-right left)))
               (node-join key value (node-right (node-right left)) right)))

  (define (node-rebalance key value left right)
    (cond
     ((too-big? (node-size left) (node-size right))
      ;; right is too big
      (if (single-rotation? (node-size (node-left right))
                            (node-size (node-right right)))
          (single-left-rotation key value left right)
          (double-left-rotation key value left right)))
     ((too-big? (node-size right) (node-size left))
      ;; left is too big
      (if (single-rotation? (node-size (node-right left))
                            (node-size (node-left left)))
          (single-right-rotation key value left right)
          (double-right-rotation key value left right)))
     (else (node-join key value left right))))


  (define (node-set node key value)
    (if (not node)
        (make-node key value 1 #f #f)
        ;; XXX: For some reason, slib wttree will compare twice using
        ;; less? using a comparator it it possible to use equal
        ;; predicate, or better use the three-way if.
        (case (lexicographer key (node-key node))
         ((less)
          ;; KEY is less than current key, recurse left side
          (node-rebalance (node-key node)
                          (node-value node)
                          (node-set (node-left node) key value)
                          (node-right node)))
         ((more)
          ;; KEY is more than current key, recurse right side
          (node-rebalance (node-key node)
                          (node-value node)
                          (node-left node)
                          (node-set (node-right node) key value)))
         (else
          ;; Otherwise, the current KEY is the one, create a new node
          ;; with associated VALUE, re-using node-left and node-right.
          ;; No need to rebalance.
          (make-node key
                     value
                     (fx+ (node-size (node-left node))
                          (node-size (node-right node))
                          1)
                     (node-left node)
                     (node-right node))))))

  (define (oktree-set oktree key value)
    (%make-oktree (node-set (oktree-root oktree)
                            key
                            value)))

  (define (oktree-ref oktree key)

    (define (ref node)
      (case (lexicographer key (node-key node))
        ((less) (and (node-left node) (ref (node-left node))))
        ((more) (and (node-right node) (ref (node-right node))))
        (else (node-value node))))

    (if (oktree-empty? oktree)
        #f
        (ref (oktree-root oktree))))

  (define (oktree->alist oktree)
    (define (node->alist node)
      (append (if (node-left node) (node->alist (node-left node)) '())
              (list (cons (node-key node) (node-value node)))
              (if (node-right node) (node->alist (node-right node)) '())))

    (node->alist (oktree-root oktree)))

  (define-record-type <oktree-cursor>
    (make-cursor oktree node stack)
    cursor?
    (oktree cursor-oktree)
    (node cursor-node cursor-node!)
    (stack cursor-stack cursor-stack!))

  (define (call-with-oktree-cursor oktree proc)
    (proc (make-cursor oktree #f '())))

  (define (oktree-cursor-position? cursor)
    (not (not (cursor-node cursor))))

  (define (node-seek-min node stack)
    (if (node-left node)
        (node-seek-min (node-left node) (cons node stack))
        (values node stack)))

  (define (node-seek-max node stack)
    (if (node-right node)
        (node-seek-max (node-right node) (cons node stack))
        (values node stack)))

  (define (oktree-cursor-seek! cursor strategy key)

    (define (cursor-seek-equal)
      (define (seek node stack)
        (case (lexicographer key (node-key node))
          ((less) (if (node-left node)
                      (seek (node-left node) (cons node stack))
                      (values 'less node stack)))
          ((more) (if (node-right node)
                      (seek (node-right node) (cons node stack))
                      (values 'more node stack)))
          (else (values 'equal node stack))))

      (seek (oktree-root (cursor-oktree cursor)) '()))

    (define (cursor-seek-equal!)
      (call-with-values cursor-seek-equal
        (lambda (found node stack)
          (case found
            ((less) 'not-found)
            ((more) 'not-found)
            ((equal)
             (cursor-node! cursor node)
             (cursor-stack! cursor stack)
             'equal)))))

    (define (cursor-seek-less-or-equal!)

      (call-with-values cursor-seek-equal
        (lambda (found node stack)
          (case found
            ((less) 'not-found)
            ((more)
             ;; KEY is bigger than (node-key node) and there is no
             ;; more near, while not being more than KEY.
             (cursor-node! cursor node)
             (cursor-stack! cursor stack)
             'less)
            ((equal) (if (node-left node)
                         (call-with-values (lambda () (seek-max (node-left node) stack))
                           (lambda (node stack)
                             (cursor-node! cursor node)
                             (cursor-stack! cursor stack)
                             'less))
                         (begin
                           (cursor-node! cursor node)
                           (cursor-stack! cursor stack)
                           'equal)))))))

    (define (cursor-seek-greather-or-equal!)

      (call-with-values cursor-seek-equal
        (lambda (found node stack)
          (case found
            ((less)
             ;; KEY is smaller than (node-key node) and there is no
             ;; more near, while not being less than KEY.
             (cursor-node! cursor node)
             (cursor-stack! cursor stack)
             'more)
            ((more) 'not-found)
            ((equal) (if (node-right node)
                         (call-with-values (lambda () (seek-min (node-right node) stack))
                           (lambda (node stack)
                             (cursor-node! cursor node)
                             (cursor-stack! cursor stack)
                             'more))
                         (begin
                           (cursor-node! cursor node)
                           (cursor-stack! cursor stack)
                           'equal)))))))

    (case strategy
      ((less-than-or-equal) (cursor-seek-less-or-equal!))
      ((equal) (cursor-seek-equal!))
      ((greather-than-or-equal) (cursor-seek-greather-or-equal!))))

  (define (oktree-cursor-next!? cursor)
    (define node (cursor-node cursor))
    (define right (node-right node))
    (define stack (cursor-stack cursor))

    (if right
        (call-with-values (lambda () (node-seek-min right (cons node stack)))
          (lambda (node stack)
            (cursor-node! cursor node)
            (cursor-stack! cursor stack)))
        (let loop ((stack stack) (node node))
          (if (null? stack)
              #f
              (let ((up (car stack)))
                (let ((up-right (node-right node)))
                  (if (eq? up-right node)
                      (loop (cdr stack) up)
                      (begin
                        (cursor-node! cursor (node-seek-min (node-right up)))
                        (cursor-stack! cursor (cdr stack))
                        #t))))))))

  (define (oktree-cursor-previous!? cursor)
    (define node (cursor-node cursor))
    (define left (node-left node))
    (define stack (cursor-stack cursor))

    (if left
        (call-with-values (lambda () (node-seek-max left (cons node stack)))
          (lambda (node stack)
            (cursor-node! cursor node)
            (cursor-stack! cursor stack)))
        (let loop ((stack stack)
                   (node node))
          (if (null? stack)
              #f
              (let ((up (car stack)))
                (let ((up-left (node-left node)))
                  (if (eq? up-left node)
                      (loop (cdr stack) up)
                      (begin
                        (cursor-node! cursor (node-seek-max (node-left up)))
                        (cursor-stack! cursor (cdr stack))
                        #t)))))))))
