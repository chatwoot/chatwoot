; Aggregate in SQL, then return only the five relevant contacts.
(query-run
  "conversations | summarize count() by contact_id | sort count desc, contact_id asc | take $n | join contacts as contact on contact_id = contact.id | return contact_id, contact.name as name, contact.email as email, count"
  (hash "n" 5))
