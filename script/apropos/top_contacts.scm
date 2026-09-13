; Fetch every page, then count and rank without an LLM per conversation.
(define all-pages
  (lambda (read-page)
    (let loop ((cursor 0) (items (list)))
      (let* ((page (read-page cursor))
             (collected (append items (get page "items")))
             (next (get page "next_cursor")))
        (if next
            (loop next collected)
            collected)))))

(define conversations
  (all-pages
    (lambda (cursor)
      (search "conversations" (hash) cursor))))

(define top-five
  (take
    (sort-by
      (count-by conversations
        (lambda (conversation) (get conversation "contact_id")))
      "count" "desc")
    5))

(map
  (lambda (entry)
    (hash
      "contact" (fetch
        (hash "type" "contacts" "id" (get entry "key")))
      "conversation_count" (get entry "count")))
  top-five)
