#!/usr/local/bin/guile \
-e main -s
!#

(use-modules (fibers) (fibers channels) (ice-9 match))

(define (montecarlopi return-chan iterations randstate)
  (define  (helper accumulator iteration) 
    (match iteration
      (0
       accumulator)                       
      (iter                                 
       (let ((x (random:uniform randstate)) (y (random:uniform randstate)) (next-iter (- iter 1))) 
         (let ((in-circle (+ (* x x) (* y y))))
           (if (< in-circle 1.0)                 
               (helper (+ accumulator 1) next-iter)  
               (helper accumulator next-iter)))))))
;  (display "started montecarlopi\n")
  (put-message return-chan (helper 0 iterations)))


(define (experiment iterations num-threads)
  (define (receive-values-over-chan chan count sum)
    (if (= count 0)
        sum
        (receive-values-over-chan chan (- count 1) (+ sum (get-message chan))
                                  ;; Receive another value over the channel, and add it to the running total
                                  )))
  (let ((iters-per-thread (/ iterations num-threads)) (return-chan (make-channel)))
    (do ((i 1 (1+ i)))
        ((> i num-threads))
      ;(display (string-join (list "creating thread #" (number->string i) "\n")))
      (spawn-fiber (lambda ()  (montecarlopi return-chan iters-per-thread (random-state-from-platform)))))
    ;(display "Finished spawning fibers\n")
    (let ((returned-sum (receive-values-over-chan return-chan num-threads 0)))
      (display (number->string (* 4.0 (/ returned-sum iterations))))
      (newline))))

(define (main args)
  ;(display (list-ref args 1))
  ;(newline)
  (set! *random-state* (random-state-from-platform))
  (let ((iterations (string->number (list-ref args 1))) (num-threads (string->number (list-ref args 2))))
    (run-fibers (lambda ()  (experiment iterations num-threads))))
  (display "All done!\n")
  (newline))
