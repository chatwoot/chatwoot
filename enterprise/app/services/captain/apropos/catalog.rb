class Captain::Apropos::Catalog
  ENTITIES = {
    'contacts' => { fields: %w[id name email phone_number identifier custom_attributes additional_attributes created_at last_activity_at],
                    query: %w[name email phone_number], relations: { 'conversations' => ['conversations', 'contact_id', :many] } },
    'conversations' => { fields: %w[id display_id status priority contact_id inbox_id assignee_id team_id
                                    custom_attributes created_at last_activity_at],
                         query_fields: { 'labels' => :string_list },
                         query: [], relations: { 'messages' => ['messages', 'conversation_id', :many],
                                                 'contact' => ['contacts', 'contact_id', :one], 'inbox' => ['inboxes', 'inbox_id', :one],
                                                 'team' => ['teams', 'team_id', :one], 'assignee' => ['agents', 'assignee_id', :one] } },
    'messages' => { fields: %w[id content message_type private conversation_id created_at], query: %w[content],
                    relations: { 'conversation' => ['conversations', 'conversation_id', :one] } },
    'inboxes' => { fields: %w[id name channel_type], query: %w[name],
                   relations: { 'conversations' => ['conversations', 'inbox_id', :many],
                                'assignable_agents' => ['agents', 'assignable_agents', :scoped] },
                   description: 'Use (related inbox-ref "assignable_agents") to read eligible agents before assignment. ' \
                                'This scoped relationship uses the same eligibility rules as assign-agent and is not a WootQL join.' },
    'teams' => { fields: %w[id name description], query: %w[name description],
                 relations: { 'conversations' => ['conversations', 'team_id', :many] } },
    'labels' => { fields: %w[id title description color show_on_sidebar created_at updated_at], query: %w[title description], relations: {} },
    'agents' => { fields: %w[id name email], query: %w[name email],
                  relations: { 'conversations' => ['conversations', 'assignee_id', :many] } },
    'articles' => { fields: %w[id title content description status portal_id], query: %w[title content], relations: {} },
    'faqs' => { fields: %w[id question answer assistant_id], query: %w[question answer], relations: {} }
  }.freeze

  FUNCTIONS = {
    'query-data' => ['(query-data "Get incoming customer messages for all open conversations")',
                     'Read-only query specialist. Returns source, result_ref, count, offset, next_cursor, query_exhausted, preview. 200 rows/page.'],
    'query-next' => ['(query-next "workspace-cursor-reference")',
                     'Fetch the next page without an LLM call. Same envelope as query-data; next_cursor is #f at end. Recall result_ref for rows.'],
    'query-map' => ['(query-map function first-page)',
                    'Calls function with each nonempty page; follows query-next. Returns result_refs, counts, progress_ref, query_exhausted. ' \
                    'On error, inspect saved progress (page, page_processed, result_refs) and receipts; callbacks are never automatically retried.'],
    'query-run' => ['(query-run "conversations | summarize count() by contact_id | sort count desc | take $n" (hash "n" 5) 0)',
                    'Execute WootQL, not SQL. Optional parameter hash and offset. Returns {items, next_offset}; 200 rows/page, #f at end.'],
    'wootql' => ['resource | where | project | join | summarize | sort | take',
                 'Read-only WootQL. Inspect member syntax. 32 stages/32 KB, 8 joins, 5s/query, 100 queries/turn including workers.'],
    'resources' => [ENTITIES.keys.join(', '), 'Available query resources. Inspect members for fields and relationships, or describe one resource.'],
    'save-function' => ['(save-function "name" "description" \'(lambda (argument) body))',
                        'Save quoted code for this user/account across chats. Replaces the same name. No captured values; body is not run.'],
    'recall' => ['(recall "workspace-reference")',
                 'Read the complete stored value into Scheme, not directly into model context. References persist across turns.'],
    'slice' => ['(slice items offset length)',
                'Read a zero-based range from a list or string. Combine with recall to inspect or reason over bounded batches.'],
    'append' => ['(append items ...)', 'Concatenate lists in argument order.'],
    'apply' => ['(apply function argument ... items)', 'Call function with the supplied arguments followed by the elements of the final list.'],
    'batches' => ['(batches items 50)',
                  'Partition a list in order, with at most N items and 16000 JSON bytes per batch for reason. Never truncates or drops items. ' \
                  'An oversized single item raises; project smaller fields or delegate it by reference.'],
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
              'Returns {operation, target, status, result, effect, at}, with no id field. Prior writes survive later errors.'],
    'reason' => ['(reason data "question" (hash "category" (list "a" "b") "reason" "string"))',
                 "Read-only reasoning, no orchestration prompt or tools. #{Captain::Apropos::ResultSchema::DESCRIPTION}"],
    'schema-check' => ['(schema-check (hash "items" (list (hash "id" "integer" "need" "string"))))',
                       "Validate and return a schema without an LLM call. #{Captain::Apropos::ResultSchema::DESCRIPTION}"],
    'delegate' => ['(delegate data "task" schema)',
                   'Fresh worker returns status, compact result, input_ref, receipts_ref, receipt_count. Recall references in the parent.'],
    'map-agent' => ['(map-agent items "task" schema)',
                    'Sequential independent workers returning compact findings and workspace references. Failures do not stop the collection.'],
    'receipts' => ['(receipts)',
                   'Success: {operation, target, status, result, effect, at}. Failure: {operation, target, status, error}. No id field.'],
    'language' => ['define, lambda, if, begin, quote, let, let*, letrec, and, or, cond',
                   'Lexical local definitions, named let, and tail calls supported. Only #f is false. No set!, macros, eval, load, or Ruby access.'],
    'let' => ['(let ((x 1)) (+ x 2)) or (let loop ((n 3)) (if (= n 0) n (loop (- n 1))))',
              'Initial values use outer scope. Named let supports loops; let* binds sequentially; letrec supports mutual recursion.'],
    'count-by' => ['(count-by records (lambda (record) (get record "contact_id")))',
                   'Returns a list of {key, count} hashes in first-seen key order. Includes every supplied record.'],
    'group-by' => ['(group-by records (lambda (record) (get record "conversation_id")))',
                   'Returns {key, items} groups in first-seen order, preserving item order within groups. Includes every supplied record.'],
    'sort-by' => ['(sort-by records "count" "desc")',
                  'Sort hashes by a field, asc or desc (default asc). Ties preserve input order. Values must be comparable.'],
    'take' => ['(take records 5)', 'Return up to the first N items; N must be a nonnegative integer.'],
    'collections' => ['Lists, hashes, higher-order functions, grouping, ranking, and bounded batches',
                      'Inspect the member contracts below for exact argument order. No implicit __last_result binding exists.'],
    'strings' => ['String operations and conversions', 'Literal string operations. No string coercion function named string.'],
    'predicates' => ['Type and value predicates', 'Inspect the actual available predicates; null? means empty list and nil? means database null.'],
    'objects' => ['Hash construction, access, and immutable updates', 'Hash updates return new values without modifying their inputs.']
  }.merge(Captain::Apropos::CoreFunctions.contracts).merge(%w[+ - * / = < > <= >=].index_with do |operator|
    ["(#{operator} left right)", 'Exactly two numeric arguments. Division follows Ruby numeric types; integer division truncates.']
  end).freeze

  COLLECTIONS = %w[list hash get keys values has-key? hash-set hash-merge car cdr cons reverse list-ref apply length null? nil? append map filter fold
                   group-by count-by sort-by take slice batches].freeze
  CORE_GROUPS = {
    'collections' => COLLECTIONS,
    'strings' => Captain::Apropos::CoreFunctions::DEFINITIONS.keys.grep(/\A(?:string|substring|number->)/),
    'predicates' => Captain::Apropos::CoreFunctions::DEFINITIONS.keys.grep(/\?\z/),
    'objects' => %w[hash get keys values has-key? hash-set hash-merge]
  }.freeze

  WOOTQL = {
    'where' => { signature: 'where status = "open" and (priority = "urgent" or assignee_id is null)',
                 description: 'Comparisons = != > >= < <=, and/or/not, is [not] null, is [not] empty, in (value, ...), contains. ' \
                              'Null means absent. Empty means zero characters/elements for text/lists only; whitespace is not empty. ' \
                              'Both empty tests yield unknown for null, excluded by where even under not. Enum names are strings.' },
    'labels' => { signature: 'conversations | where labels contains "refund"',
                  description: 'Conversation labels are a non-null string list, returned as an array. contains tests exact membership. ' \
                               'Use labels is empty for no labels ([]), is not empty for any labels. is null never matches base conversations. ' \
                               'A missing conversation on the right of a left join yields null, not an empty list.' },
    'project' => { signature: 'project id, status, inbox.name as inbox_name',
                   description: 'Keep or rename fields. To-one dotted paths become scoped left joins. Retain IDs and ordering keys for pagination.' },
    'join' => { signature: 'join contacts as contact on contact_id = contact.id',
                description: 'Equality join with any exposed resource. Use join left for a left join. Right fields use the alias prefix.' },
    'summarize' => { signature: 'summarize count() as total, count_distinct(contact_id) as customers by inbox_id',
                     description: 'count, count_distinct, sum, avg, min, max. Only count() omits its field. Omit by to aggregate all rows.' },
    'sort' => { signature: 'sort total desc, inbox_id asc', description: 'asc (default) or desc; nulls last. Include unique tie-breakers.' },
    'take' => { signature: 'take 5', description: 'Limit this pipeline stage. take before where differs from where before take.' },
    'values' => { signature: 'where created_at >= now() - 7d | where contact_id = $contact',
                  description: 'Strings, numbers, true/false, $parameters, now() minus ms/s/m/h/d/w. Parameters are data, never syntax.' }
  }.freeze

  ACTIONS = {
    'add-private-note' => { target: 'conversations', arguments: { content: 'string' }, effect: 'internal_write' },
    'send-reply' => { target: 'conversations', arguments: { content: 'string' }, effect: 'external_write' },
    'set-status' => { target: 'conversations', arguments: { status: 'open | resolved | pending' }, effect: 'internal_write' },
    'set-priority' => { target: 'conversations', arguments: { priority: 'low | medium | high | urgent' }, effect: 'internal_write' },
    'assign-team' => { target: 'conversations', arguments: { team_id: 'account team database ID' }, effect: 'internal_write' },
    'assign-agent' => { target: 'conversations', arguments: { agent_id: 'account agent database ID' }, effect: 'internal_write' },
    'add-label' => { target: 'conversations', arguments: { label: 'existing account label title' }, effect: 'internal_write' }
  }.freeze

  def initialize(scheme, library: nil)
    @scheme = scheme
    @library = library
  end

  def entries
    functions = FUNCTIONS.transform_values { |signature, description| { signature: signature, description: description } }
    CORE_GROUPS.each { |name, members| functions[name] = functions.fetch(name).merge(members: functions.slice(*members)) }
    functions['wootql'] = functions.fetch('wootql').merge(members: WOOTQL)
    functions['resources'] = functions.fetch('resources').merge(members: ENTITIES)
    functions.merge(ENTITIES).merge(ACTIONS)
             .merge(@library ? @library.entries : {})
             .merge(@scheme.bindings.transform_keys(&:to_s).transform_values do |value|
                      { stored_value: Captain::Apropos::ContextLimits.describe(value) }
                    end)
  end

  def apropos(query)
    terms = query.downcase.split
    entries.select { |name, details| terms.empty? || terms.any? { |term| "#{name} #{details.to_json}".downcase.include?(term) } }
           .transform_values { |details| discovery_summary(details) }
  end

  def describe(name)
    if @scheme.bindings.key?(name.to_sym)
      value = @scheme.bindings.fetch(name.to_sym)
      details = { ref: name, stored_value: Captain::Apropos::ContextLimits.describe(value) }
      if value.is_a?(Captain::Apropos::Scheme::Closure)
        details[:binding] = { type: 'closure', parameters: Captain::Apropos::Codec.dump(value.parameters),
                              body: Captain::Apropos::Codec.dump(value.body) }
      end
      return details
    end
    return @library.describe(name) if @library&.entries&.key?(name)

    entries.fetch(name.to_s) { raise Captain::Apropos::Error, "Unknown catalog entry: #{name}" }
  end

  private

  def discovery_summary(details)
    return details.slice(:signature, :description) if details.key?(:signature)
    return { fields: details[:fields] + details.fetch(:query_fields, {}).keys, connections: details.fetch(:relations).keys } if details.key?(:fields)

    details.slice(:target, :effect, :stored_value)
  end
end
