class Captain::Apropos::Runtime
  include Captain::Apropos::QueryFunctions

  MAX_AGENT_CALLS = 100
  MAX_DELEGATION_DEPTH = 2

  attr_reader :scheme, :catalog, :events, :account, :user

  def initialize(account:, user:, state: {}, on_event: nil, execution: { budget: { calls: 0, queries: 0 }, depth: 0 })
    Captain::Apropos::Access.check!(account, user)
    @account = account
    @user = user
    @on_event = on_event
    @budget = execution.fetch(:budget)
    @depth = execution.fetch(:depth)
    @events = []
    @scheme = Captain::Apropos::Scheme.new(bindings: state.empty? ? {} : Captain::Apropos::Codec.load(state))
    @library = Captain::Apropos::Library.new(account: account, user: user, scheme: scheme)
    @catalog = Captain::Apropos::Catalog.new(scheme, library: @library)
    @data = Captain::Apropos::DataAccess.new(account: account, user: user)
    @query = Captain::Apropos::Query.new(data: @data, budget: @budget)
    @actions = Captain::Apropos::Actions.new(account: account, user: user, data: @data, record: method(:record))
    install_functions
    @query.install(scheme)
    Captain::Apropos::FaqSearch.new(data: @data, account: account, consume: method(:consume_agent_call!)).install(scheme)
  end

  def execute(source)
    record('program', { 'source' => source })
    value = scheme.execute(source)
    state # Check that new bindings can be persisted before reporting success.
    output = model_value(present(value))
    record('result', { 'value' => output })
    output
  rescue StandardError => e
    record('error', { 'message' => e.message })
    raise
  end

  def state
    Captain::Apropos::Codec.dump(scheme.bindings)
  end

  def execution_progress
    {
      completed_bindings: scheme.completed_bindings,
      failed_binding: scheme.failed_binding,
      available_bindings: scheme.bindings.keys.reject { |name| name.to_s.start_with?('workspace-') }.map(&:to_s)
    }
  end

  def run_context = Captain::Apropos::Prompt.context(account: account, budget: @budget, depth: @depth)

  def record(kind, data)
    event = { 'kind' => kind, 'data' => data, 'depth' => @depth, 'at' => Time.current.iso8601 }
    events << event
    @on_event&.call(event)
  end

  def receipts
    events.select { |event| event['kind'] == 'action' }.pluck('data')
  end

  def store(value)
    reference = "workspace-#{SecureRandom.hex(8)}"
    Captain::Apropos::Codec.dump(value)
    scheme.bindings[reference.to_sym] = value
    reference
  end

  def model_value(value, limit: Captain::Apropos::ContextLimits::TOOL_BYTES)
    bytes = JSON.generate(value).bytesize
    return value if bytes <= limit

    reference = store(value)
    preview = Captain::Apropos::ContextLimits.preview(value)
    preview = Captain::Apropos::ContextLimits.describe(value) if JSON.generate(preview).bytesize > limit / 2
    { 'truncated' => true, 'ref' => reference, 'bytes' => bytes, 'value_info' => Captain::Apropos::ContextLimits.describe(value),
      'preview' => preview, 'instruction' => 'Preview only. Use (recall "ref") inside Scheme; filter, slice, or delegate before returning data.' }
  end

  def reply(value)
    model_value(value).to_json
  end

  def model_input(input, tools:)
    if !tools && JSON.generate(input).bytesize > Captain::Apropos::ContextLimits::REASON_INPUT_BYTES
      raise Captain::Apropos::Error, 'reason input exceeds 16000 bytes. Split the data into smaller batches; no reasoning was performed.'
    end

    tools ? model_value(input) : input
  end

  def model_history(history)
    remaining = Captain::Apropos::ContextLimits::HISTORY_BYTES
    history.reverse_each.filter_map do |message|
      content = model_value(message.fetch(:content), limit: 4_000)
      entry = message.merge(content: content.is_a?(String) ? content : JSON.generate(content))
      remaining -= JSON.generate(entry).bytesize
      entry if remaining >= 0
    end.reverse
  end

  def ask(instruction, input: nil, schema: nil, tools: true, history: [])
    consume_agent_call!

    response = Captain::Apropos::AgentService.new(
      account: account, runtime: self, instruction: instruction, input: input,
      result_schema: schema, tools_enabled: tools, history: history
    ).perform
    raise Captain::Apropos::Error, response[:error] if response[:error]

    response.fetch(:message)
  end

  private

  def consume_agent_call!
    @budget[:calls] += 1
    raise Captain::Apropos::Error, 'Agent call budget exhausted' if @budget[:calls] > MAX_AGENT_CALLS
  end

  def install_functions
    scheme.register('apropos') { |query| catalog.apropos(query) }
    scheme.register('describe') { |name| catalog.describe(name) }
    @data.install(scheme)
    scheme.register('act') { |name, ref, arguments| @actions.call(name, ref, arguments) }
    install_agent_functions
    install_workspace_functions
  end

  def install_agent_functions
    scheme.register('query-data') { |instruction| query_data(instruction) }
    scheme.register('query-next') { |reference| query_next(reference) }
    scheme.register('query-map') { |function, page| query_map(function, page) }
    scheme.register('reason') { |data, task, schema| reason(data, task, schema) }
    scheme.register('delegate') { |data, task, schema| delegate(data, task, schema) }
    scheme.register('map-agent') { |items, task, schema| items.map { |item| delegate(item, task, schema) } }
  end

  def install_workspace_functions
    table_display = Captain::Apropos::TableDisplay.new(record: method(:record))
    scheme.register('show-table') { |rows, columns| table_display.call(rows, columns) }
    scheme.register('schema-check') do |fields|
      Captain::Apropos::ResultSchema.build(fields)
      fields
    end
    scheme.register('recall') { |reference| scheme.bindings.fetch(reference.to_sym) }
    scheme.register('slice') { |value, offset, length| slice(value, offset, length) }
    scheme.register('receipts') { receipts }
    scheme.register('save-function') { |name, description, expression| @library.save(name, description, expression) }
  end

  def reason(input, task, schema)
    reason_id = SecureRandom.uuid
    record('reason', { 'reason_id' => reason_id, 'instruction' => task, 'schema' => schema,
                       'input' => model_value(input) })
    result = ask(task, input: input, schema: schema, tools: false)
    record('reason_result', { 'reason_id' => reason_id, 'value' => model_value(result) })
    result
  rescue StandardError => e
    record('error', { 'reason_id' => reason_id, 'message' => e.message })
    raise
  end

  def delegate(input, task, schema)
    input_ref = store(input)
    raise Captain::Apropos::Error, 'Delegation depth exceeded' if @depth >= MAX_DELEGATION_DEPTH

    child = self.class.new(account: account, user: user, execution: { budget: @budget, depth: @depth + 1 },
                           on_event: lambda { |event|
                             events << event
                             @on_event&.call(event)
                           })
    result = child.ask(task, input: input, schema: schema)
    retain_worker_workspace(child)
    { 'input_ref' => input_ref, 'status' => 'completed', 'result' => model_value(result, limit: 4_000),
      'receipts_ref' => store(child.receipts), 'receipt_count' => child.receipts.size }
  rescue StandardError => e
    retain_worker_workspace(child) if child
    captured_receipts = child ? child.receipts : []
    { 'input_ref' => input_ref, 'status' => 'failed', 'error' => model_value(e.message, limit: 1_000),
      'receipts_ref' => store(captured_receipts), 'receipt_count' => captured_receipts.size }
  end

  def retain_worker_workspace(child)
    child.scheme.bindings.each do |name, value|
      scheme.bindings[name] = value if name.to_s.start_with?('workspace-')
    end
  end

  def slice(value, offset, length)
    unless [Array, String].any? { |type| value.is_a?(type) } && [offset, length].all? { |number| number.is_a?(Integer) && number >= 0 }
      raise Captain::Apropos::Error, 'slice expects a list or string, a nonnegative offset, and a nonnegative length'
    end

    value.slice(offset, length) || value.slice(0, 0)
  end

  def present(value)
    case value
    when Captain::Apropos::Scheme::Closure, Proc then 'procedure (inspect its binding with describe)'
    when Hash then value.to_h { |key, item| [key.to_s, present(item)] }
    when Array then value.map { |item| present(item) }
    else value.as_json
    end
  end
end
