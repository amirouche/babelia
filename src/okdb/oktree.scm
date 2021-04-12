(library (okdb oktree)
  (export make-oktree
          oktree-set
          oktree-ref
          oktree->alist)

  (import (scheme base)
          (scheme fixnum))

  ;; oktree is a persistent binary balanced binary tree that use
  ;; logarithmic measure to (try...) to balance the tree. It only
  ;; support bytevector as keys. It can only have `fx-greatest` keys
  ;; in the tree.

  ;; TODO: add reference to the paper and re-read it.

  ;; TODO: do some tests to see if it properly balanced.

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
     (else (make-node key
                      value
                      (fx+ (node-size left)
                           (node-size right)
                           1)
                      left
                      right))))

  (define (node-set node less? key value)
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
                          (node-set (node-left node) less? key value)
                          (node-right node)))
         ((more)
          ;; KEY is more than current key, recurse right side
          (node-rebalance (node-key node)
                          (node-value node)
                          (node-left node)
                          (node-set (node-right node) less? key value)))
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
    (if (oktree-empty? oktree)
        (%make-oktree (oktree-comparator oktree)
                      (make-node key value 1 #f #f))
        (%make-oktree (oktree-comparator oktree)
                      (node-set (oktree-root oktree)
                                (oktree-comparator oktree)
                                key
                                value))))

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
