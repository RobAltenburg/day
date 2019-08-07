(import (prefix sql-de-lite "sql:")
        (prefix (chicken time) "time:")
        (prefix (chicken time posix) "ptime:")
        (prefix (chicken file) "file:")
        (prefix (chicken process-context posix) "posix:"))

;; convert unix time to ical time and back
(define (unix-time->ical tt)
  (- tt 978307200))
(define (ical->unix-time tt)
  (+ tt 978307200))

;; open the calendar Cache database
(define cache-file (string-append "/Users/"
                                  (posix:current-user-name)
                                  "/Library/Calendars/Calendar Cache"))
;; print the results
(define (cal-print in-list)
  (unless (null? in-list)
    (let* ((line (car in-list))
           (start (ptime:seconds->local-time (ical->unix-time (car line))))
           (end (ptime:seconds->local-time (ical->unix-time (car (cdr line))))))
      (print (car (reverse line)) " || " 
             (ptime:time->string start "%I:%M%p %a %D") " – " 
             (ptime:time->string end "%I:%M%p %a %D")))
    (cal-print (cdr in-list))))

(if (file:file-exists? cache-file)
    (begin
      (let* ((db (sql:open-database cache-file))
             (now (unix-time->ical (time:current-seconds)))
             (end (+ now 86400))
             (s (sql:sql db 
                         (string-append "select ZSTARTDATE, ZENDDATE, ZTITLE from ZCALENDARITEM "
                                        "where ZSTARTDATE > " (number->string now) " "
                                        "and ZSTARTDATE < " (number->string end)))))

        (cal-print (sql:query sql:fetch-rows s))
        (sql:close-database db)))
    (print "No cache found at: " cache-file))
