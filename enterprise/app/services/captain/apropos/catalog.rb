class Captain::Apropos::Catalog
  ENTITIES = {
    'contacts' => { fields: %w[id name email phone_number identifier custom_attributes additional_attributes created_at last_activity_at],
                    query: %w[name email phone_number], relations: { 'conversations' => ['conversations', 'contact_id', :many] } },
    'conversations' => { fields: %w[id display_id status priority contact_id inbox_id assignee_id team_id
                                    custom_attributes created_at last_activity_at],
                         query: [], relations: { 'messages' => ['messages', 'conversation_id', :many],
                                                 'contact' => ['contacts', 'contact_id', :one], 'inbox' => ['inboxes', 'inbox_id', :one],
                                                 'team' => ['teams', 'team_id', :one], 'assignee' => ['agents', 'assignee_id', :one] } },
    'messages' => { fields: %w[id content message_type private conversation_id created_at], query: %w[content],
                    relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
    'inboxes' => { fields: %w[id name channel_type], query: %w[name],
                   relations: { 'conversations' => ['conversations', 'inbox_id', :many] } },
    'teams' => { fields: %w[id name description], query: %w[name description],
                 relations: { 'conversations' => ['conversations', 'team_id', :many] } },
    'agents' => { fields: %w[id name email], query: %w[name email],
                  relations: { 'conversations' => ['conversations', 'assignee_id', :many] } },
    'articles' => { fields: %w[id title content description status portal_id], query: %w[title content], relations: {} },
    'faqs' => { fields: %w[id question answer assistant_id], query: %w[question answer], relations: {} }
  }.freeze

  FUNCTIONS = {
    'list' => ['(list value ...)', 'Build a list; (list) returns an empty list.'],
    'hash' => ['(hash "key" value ...)', 'Build a hash from alternating keys and values. Keys become strings.'],
    'get' => ['(get hash "key")', 'Read a required hash field. Missing keys are errors.'],
    'car' => ['(car items)', 'Return the first list item. Empty lists are errors.'],
    'cdr' => ['(cdr items)', 'Return the list without its first item.'],
    'length' => ['(length items)', 'Return the size of a list, hash, or string.'],
    'null?' => ['(null? value)', 'True only for an empty list, not for #f.'],
    'not' => ['(not value)', 'True only when value is #f.'],
    'equal?' => ['(equal? left right)', 'Compare values, including strings and lists, for equality.'],
    'append' => ['(append items ...)', 'Concatenate lists in argument order.'],
    'map' => ['(map function items)', 'Function FIRST, list SECOND. Calls function with each item and returns the results.'],
    'filter' => ['(filter predicate items)', 'Predicate FIRST, list SECOND. Keep items whose predicate result is not #f.'],
    'fold' => ['(fold function initial items)', 'Calls function with accumulator then item, returning the final accumulator.'],
    'define' => ['(define name value) or (define (name args ...) body ...)', 'Save a binding in the current lexical scope.'],
    'lambda' => ['(lambda (args ...) body ...)', 'Create a fixed-arity function capturing its lexical scope.'],
    'if' => ['(if condition consequent alternative)', 'Evaluate only the chosen branch. Only #f is false.'],
    'begin' => ['(begin expression ...)', 'Evaluate expressions in order; return the last result.'],
    'quote' => ['(quote expression)', 'Return literal data without evaluation. Apostrophe syntax is equivalent.'],
    'let*' => ['(let* ((name expression) ...) body ...)', 'Bind sequentially; later expressions see earlier bindings.'],
    'letrec' => ['(letrec ((name expression) ...) body ...)', 'Shared lexical scope for recursive functions.'],
    'and' => ['(and expression ...)', 'Short-circuit on #f; otherwise return the last value. Empty and returns #t.'],
    'or' => ['(or expression ...)', 'Return the first non-#f value. Empty or returns #f.'],
    'cond' => ['(cond (condition body ...) ... (else body ...))', 'Evaluate the first matching clause. Optional else must be last; no => clauses.'],
    'apropos' => ['(apropos "words")', 'Search functions, entities, relationships, and saved bindings.'],
    'describe' => ['(describe "name")', 'Read the exact contract of a function, entity, operation, or binding.'],
    'search' => ['(search "contacts" (hash "email" "maya@example.com") 0)',
                 'Page records using exact field filters, query text, or labels. Returns items and next_cursor.'],
    'fetch' => ['(fetch (hash "type" "contacts" "id" 42))', 'Read a record by reference; IDs are database IDs, not display IDs.'],
    'related' => ['(related ref "conversations" 0)', 'Follow a declared relationship. Always returns a page; use next_cursor for more.'],
    'act' => ['(act "add-private-note" ref (hash "content" "Hello"))',
              'Execute an explicit operation. Returns a receipt; prior writes survive later errors.'],
    'reason' => ['(reason data "question" (hash "category" (list "a" "b") "reason" "string"))',
                 'Read-only LLM reasoning. Schema fields: string, boolean, integer, string_list, or a list of enum strings.'],
    'delegate' => ['(delegate data "task" schema)',
                   'Fresh agent context and Scheme bindings with the same account authority. Returns result and receipts.'],
    'map-agent' => ['(map-agent items "task" schema)',
                    'Sequential independent workers. Each returns input, status, result, and receipts. Failed workers do not stop the collection.'],
    'receipts' => ['(receipts)', 'Read action receipts captured during this turn, including delegated actions.'],
    'language' => ['define, lambda, if, begin, quote, let, let*, letrec, and, or, cond',
                   'Lexical local definitions, named let, and tail calls supported. Only #f is false. No set!, macros, eval, load, or Ruby access.'],
    'let' => ['(let ((x 1)) (+ x 2)) or (let loop ((n 3)) (if (= n 0) n (loop (- n 1))))',
              'Initial values use outer scope. Named let supports loops; let* binds sequentially; letrec supports mutual recursion.'],
    'count-by' => ['(count-by records (lambda (record) (get record "contact_id")))',
                   'Returns a list of {key, count} hashes in first-seen key order. Includes every supplied record.'],
    'sort-by' => ['(sort-by records "count" "desc")',
                  'Sort hashes by a field, asc or desc (default asc). Ties preserve input order. Values must be comparable.'],
    'take' => ['(take records 5)', 'Return up to the first N items; N must be a nonnegative integer.'],
    'collections' => ['list, hash, get, car, cdr, length, null?, append, map, filter, fold, count-by, sort-by, take',
                      'Inspect the member contracts below for exact argument order. No implicit __last_result binding exists.']
  }.merge(%w[+ - * / = < > <= >=].index_with do |operator|
    ["(#{operator} left right)", 'Exactly two numeric arguments. Division follows Ruby numeric types; integer division truncates.']
  end).freeze

  COLLECTIONS = %w[list hash get car cdr length null? append map filter fold count-by sort-by take].freeze

  ACTIONS = {
    'add-private-note' => { target: 'conversations', arguments: { content: 'string' }, effect: 'internal_write' },
    'send-reply' => { target: 'conversations', arguments: { content: 'string' }, effect: 'external_write' },
    'set-status' => { target: 'conversations', arguments: { status: 'open | resolved | pending' }, effect: 'internal_write' },
    'set-priority' => { target: 'conversations', arguments: { priority: 'low | medium | high | urgent' }, effect: 'internal_write' },
    'assign-team' => { target: 'conversations', arguments: { team_id: 'account team database ID' }, effect: 'internal_write' },
    'assign-agent' => { target: 'conversations', arguments: { agent_id: 'account agent database ID' }, effect: 'internal_write' },
    'add-label' => { target: 'conversations', arguments: { label: 'existing account label title' }, effect: 'internal_write' }
  }.freeze

  def initialize(scheme)
    @scheme = scheme
  end

  def entries
    functions = FUNCTIONS.transform_values { |signature, description| { signature: signature, description: description } }
    functions['collections'] = functions.fetch('collections').merge(members: functions.slice(*COLLECTIONS))
    functions.merge(ENTITIES).merge(ACTIONS)
             .merge(@scheme.bindings.transform_keys(&:to_s).transform_values { |value| { binding: Captain::Apropos::Codec.dump(value) } })
  end

  def apropos(query)
    terms = query.downcase.split
    entries.select { |name, details| terms.empty? || terms.any? { |term| "#{name} #{details.to_json}".downcase.include?(term) } }
  end

  def describe(name)
    entries.fetch(name.to_s) { raise Captain::Apropos::Error, "Unknown catalog entry: #{name}" }
  end
end
