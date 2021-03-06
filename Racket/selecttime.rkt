#lang racket/base

(require racket/random racket/match)
(require racket/place)

(define (create-chans length)
  (define (helper iteration rxes txes)
    (match iteration
      [0 (values rxes txes)]
      [iter
       (let-values ([(rx tx) (place-channel)])
         (helper (sub1 iteration) (list* rx rxes) (list* tx txes)))]))
  (helper length null null))

(define (place/sender iterations channels)
  (place/context
   c
   (begin
     (define (sender iteration)
       (let ([choice-chan (random-ref channels)])
         (match iteration
           [0
            (begin (place-channel-put choice-chan 'NONE)
                   (displayln "Sender completed."))]
           [iter
            (place-channel-put choice-chan iter)
            (sender (sub1 iter))])))
     (sender iterations))))

(define (place/receiver channels)
  (place/context
   c
   (begin
     (define (receive-and-process channels)
       (match (apply sync channels)
         ['NONE
          (displayln "Receiver completed")]
         [Some
          (receive-and-process channels)]))

     (receive-and-process channels))))

(define (experiment iterations num-channels)
  (let-values ([(ch-rxes ch-txes) (create-chans num-channels)])
    (let ([r (place/receiver ch-rxes)]
          [s (place/sender iterations ch-txes)])
      (place-wait r)
      (place-wait s))))

(module+ main
  (define cmd-params (current-command-line-arguments))
  (define iterations (string->number (vector-ref cmd-params 0)))
  (define num-channels (string->number (vector-ref cmd-params 1)))
  (experiment iterations num-channels)
  (displayln "Select Time completed successfully"))
