require 'wootql'

class Captain::Apropos::Catalog
  ENTITIES = Captain::Apropos::ResourceCatalog::ENTITIES

  FUNCTIONS = {
    'show-table' => ['(show-table rows (list "name" "conversation_count"))',
                     'Display a table in your answer. Optional typed columns format dates, numbers, statuses, tags, and conversation/contact links.'],
    'faq-search' => ['(faq-search "How do refunds work?" 42)',
                     'Semantic search of approved Captain FAQs. Optional assistant ID; omit for this account. Inspect contract for costs and scope.'],
    'assignment-context' => ['(assignment-context (hash "type" "inboxes" "id" 10) 0)',
                             'Read assignment policies, availability, and inbox capacity. Inspect the full contract before assigning.'],
    'query-run' => ['(query-run "conversations | summarize count() by contact_id | sort count desc | take $n" (hash "n" 5) 0)',
                    'Execute WootQL. Returns a page: kind=page, items (list), item_count (integer), has_more (boolean), query_ref, offset, next_offset. ' \
                    '200 items/page. item_count is this page only, not a total or analyzed count. Query handles last for this turn.'],
    'query-next' => ['(query-next page)',
                     'Fetch the next page of a query-run/query-next result. Returns another page or #f when the query is exhausted.'],
    'query-map' => ['(query-map function first-page)',
                    'Calls function with the items from every nonempty page; follows query-next. ' \
                    'Returns kind=processing_result, status, processed_item_count, processed_page_count, results (list of stored_value references), ' \
                    'progress_ref, query_exhausted. Recall each result ref to read callback output. Counts are numbers, not lists. ' \
                    'On error, inspect progress and receipts; callbacks are never automatically retried.'],
    'wootql' => ['resource | where | return | join | summarize | sort | take',
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
                  "Partition a list in order, with at most N items and #{Captain::Apropos::ContextLimits::REASON_INPUT_BYTES} JSON bytes per " \
                  'batch for reason. Never truncates or drops items. ' \
                  'An oversized single item raises; return fewer fields or give its reference to spawn-agent.'],
    'map' => ['(map function items)', 'Function FIRST, list SECOND. Calls function with each item and returns the results.'],
    'filter' => ['(filter predicate items)', 'Predicate FIRST, list SECOND. Keep items whose predicate result is not #f.'],
    'fold' => ['(fold function initial items)', 'Calls function with accumulator then item, returning the final accumulator.'],
    'define' => ['(define name value) or (define (name args ...) body ...)', 'Save a binding in the current lexical scope.'],
    'lambda' => ['(lambda (args ...) body ...)', 'Create a lexical function. Dotted/rest parameter lists are supported.'],
    'if' => ['(if condition consequent alternative)', 'Evaluate only the chosen branch. Only #f is false.'],
    'begin' => ['(begin expression ...)', 'Evaluate expressions in order; return the last result.'],
    'quote' => ['(quote expression)', 'Return literal data without evaluation. Apostrophe syntax is equivalent.'],
    'let*' => ['(let* ((name expression) ...) body ...)', 'Bind sequentially; later expressions see earlier bindings.'],
    'letrec' => ['(letrec ((name expression) ...) body ...)', 'Shared lexical scope for recursive functions.'],
    'and' => ['(and expression ...)', 'Short-circuit on #f; otherwise return the last value. Empty and returns #t.'],
    'or' => ['(or expression ...)', 'Return the first non-#f value. Empty or returns #f.'],
    'cond' => ['(cond (condition body ...) ... (else body ...))', 'Evaluate the first matching clause. Supports => clauses; else must be last.'],
    'apropos' => ['(apropos "words")', 'Search functions, entities, relationships, and saved bindings.'],
    'describe' => ['(describe "name")', 'Read the exact contract of a function, entity, operation, or binding.'],
    'search' => ['(search "contacts" (hash "email" "maya@example.com") 0)',
                 'Returns kind=record_page, items (list), item_count (this page only), has_more and next_cursor. ' \
                 'Use exact field filters, query text, or labels. Follow next_cursor until #f.'],
    'fetch' => ['(fetch (hash "type" "contacts" "id" 42))', 'Read a record by reference; IDs are database IDs, not display IDs.'],
    'related' => ['(related ref "conversations" 0)',
                  'Follow a relationship. Returns kind=record_page, items, item_count, has_more, next_cursor. Use next_cursor for more.'],
    'act' => ['(act "add-private-note" ref (hash "content" "Hello"))',
              'Returns {operation, target, status, result, effect, at}, with no id field. Prior writes survive later errors.'],
    'reason' => ['(reason data "question" (hash "category" (list "a" "b") "reason" "string"))',
                 "Read-only reasoning, no orchestration prompt or tools. #{Captain::Apropos::ResultSchema::DESCRIPTION}"],
    'schema-check' => ['(schema-check (hash "items" (list (hash "id" "integer" "need" "string"))))',
                       "Validate and return a schema without an LLM call. #{Captain::Apropos::ResultSchema::DESCRIPTION}"],
    'spawn-agent' => ['(spawn-agent data "task" schema)',
                      'Run a fresh autonomous Apropos worker with tools. Returns status, compact result, input_ref, receipts_ref, and ' \
                      'receipt_count. Use standard map for repeated independent work.'],
    'receipts' => ['(receipts)',
                   'Success: {operation, target, status, result, effect, at}. Failure: {operation, target, status, error}. No id field.'],
    'language' => ['Scheme with Chatwoot extensions',
                   'R7RS-small-oriented interpreter with preloaded standard procedures, real pairs/lists, lexical definitions, set!, ' \
                   'named let, tail calls, multiple values and continuations. Imports are ignored. Not fully R7RS compliant. ' \
                   'No filesystem, eval, load, macros or Ruby access. Inspect discovered procedures for available operations. ' \
                   'Live control objects cannot be persisted between turns; save data and lambdas.'],
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
  }.merge(Captain::Apropos::CoreFunctions.contracts).freeze

  COLLECTIONS = %w[list hash get keys hash-values has-key? hash-set hash-merge car cdr cons reverse list-ref apply length null? nil? append map filter fold
                   group-by count-by sort-by take slice batches].freeze
  CORE_GROUPS = {
    'collections' => COLLECTIONS,
    'strings' => Captain::Apropos::CoreFunctions::DEFINITIONS.keys.grep(/\A(?:string|substring|number->)/),
    'predicates' => Captain::Apropos::CoreFunctions::DEFINITIONS.keys.grep(/\?\z/),
    'objects' => %w[hash get keys hash-values has-key? hash-set hash-merge]
  }.freeze

  WOOTQL = Wootql::Contracts::STAGES

  ACTIONS = Captain::Apropos::ActionContracts::DEFINITIONS

  def initialize(scheme, library: nil)
    @scheme = scheme
    @library = library
  end

  def entries
    Captain::Apropos::SeeAlso.attach(function_entries.merge(resource_entries).merge(ACTIONS))
                             .merge(Captain::Apropos::Knowledge.entries)
                             .merge(@library ? @library.entries : {})
                             .merge(@scheme.workspace.transform_keys(&:to_s).transform_values do |value|
                                      { stored_value: Captain::Apropos::ContextLimits.describe(value) }
                                    end)
  end

  def apropos(query)
    terms = query.downcase.split
    entries.select { |name, details| terms.empty? || terms.any? { |term| "#{name} #{details.except(:see_also).to_json}".downcase.include?(term) } }
           .transform_values { |details| discovery_summary(details).merge(details.slice(:see_also)) }
  end

  def describe(name)
    if @scheme.workspace.key?(name.to_sym)
      value = @scheme.workspace.fetch(name.to_sym)
      details = { ref: name, stored_value: Captain::Apropos::ContextLimits.describe(value) }
      if value.is_a?(::Scheme::Closure)
        details[:binding] = { type: 'closure', source: ::Scheme.write(::Scheme.list([:lambda, value.parameters, *value.body])) }
      end
      return details
    end
    return @library.describe(name) if @library&.entries&.key?(name)

    entries.fetch(name.to_s) { raise Captain::Apropos::Error, "Unknown catalog entry: #{name}" }
  end

  private

  def resource_entries
    knowledge = Captain::Apropos::Knowledge.entries
    Captain::Apropos::ResourceCatalog.entries.to_h do |name, definition|
      concept = knowledge["knowledge/#{name == 'agents' ? 'human-agents' : name}"]
      metadata = Captain::Apropos::ResourceFields.metadata(name, definition.fetch(:fields))
      definition.fetch(:query_fields, {}).each { |field, type| metadata[field] = { type: type, nullable: false, computed: true } }
      [name, definition.merge(field_metadata: metadata).merge(concept ? concept.slice(:markdown, :concept_relations) : {})]
    end
  end

  def function_entries
    functions = @scheme.standard_contracts.merge(FUNCTIONS.transform_values do |signature, description|
      { signature: signature, description: description }
    end)
    CORE_GROUPS.each { |name, members| functions[name] = functions.fetch(name).merge(members: functions.slice(*members)) }
    functions['strings'][:members] = functions.select { |name, _| name.match?(/\A(?:string|substring|number->)/) && name != 'strings' }
    functions['predicates'][:members] = functions.select { |name, _| name.end_with?('?') }
    functions['wootql'] = functions.fetch('wootql').merge(members: WOOTQL)
    functions['resources'] = functions.fetch('resources').merge(members: resource_entries)
    functions['assignment-context'] = functions.fetch('assignment-context').merge(Captain::Apropos::AssignmentContext::CONTRACT)
    functions['faq-search'] = functions.fetch('faq-search').merge(Captain::Apropos::FaqSearch::CONTRACT)
    functions['show-table'] = functions.fetch('show-table').merge(Captain::Apropos::TableDisplay::CONTRACT)
    functions
  end

  def discovery_summary(details)
    return details.slice(:kind, :description, :concept_relations) if details[:kind] == 'knowledge'

    return details.slice(:signature, :description) if details.key?(:signature)
    return { fields: details[:fields] + details.fetch(:query_fields, {}).keys, connections: details.fetch(:relations).keys } if details.key?(:fields)

    details.slice(:target, :effect, :description, :stored_value)
  end
end
