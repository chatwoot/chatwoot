class Captain::Apropos::Runtime
  MAX_AGENT_CALLS = 100
  MAX_DELEGATION_DEPTH = 2

  attr_reader :scheme, :catalog, :events, :account, :user

  def initialize(account:, user:, state: {}, on_event: nil, execution: { budget: { calls: 0 }, depth: 0 })
    Captain::Apropos::Access.check!(account, user)
    @account = account
    @user = user
    @on_event = on_event
    @budget = execution.fetch(:budget)
    @depth = execution.fetch(:depth)
    @events = []
    @scheme = Captain::Apropos::Scheme.new(bindings: state.empty? ? {} : Captain::Apropos::Codec.load(state))
    @catalog = Captain::Apropos::Catalog.new(scheme)
    @data = Captain::Apropos::DataAccess.new(account: account, user: user)
    @actions = Captain::Apropos::Actions.new(account: account, user: user, data: @data, record: method(:record))
    install_functions
  end

  def execute(source)
    record('program', { 'source' => source })
    value = scheme.execute(source)
    state # Check that new bindings can be persisted before reporting success.
    record('result', { 'value' => present(value) })
    present(value)
  rescue StandardError => e
    record('error', { 'message' => e.message })
    raise
  end

  def state
    Captain::Apropos::Codec.dump(scheme.bindings)
  end

  def record(kind, data)
    event = { 'kind' => kind, 'data' => data, 'depth' => @depth, 'at' => Time.current.iso8601 }
    events << event
    @on_event&.call(event)
  end

  def receipts
    events.select { |event| event['kind'] == 'action' }.pluck('data')
  end

  def ask(instruction, input: nil, schema: nil, tools: true, history: [])
    @budget[:calls] += 1
    raise Captain::Apropos::Error, 'Agent call budget exhausted' if @budget[:calls] > MAX_AGENT_CALLS

    response = Captain::Apropos::AgentService.new(
      account: account, runtime: self, instruction: instruction, input: input,
      result_schema: schema, tools_enabled: tools, history: history
    ).perform
    raise Captain::Apropos::Error, response[:error] if response[:error]

    response.fetch(:message)
  end

  private

  def install_functions
    scheme.register('apropos') { |query| catalog.apropos(query) }
    scheme.register('describe') { |name| catalog.describe(name) }
    scheme.register('search') { |type, filters = {}, cursor = 0| @data.search(type, filters, cursor) }
    scheme.register('fetch') { |ref| @data.fetch(ref) }
    scheme.register('related') { |ref, name, cursor = 0| @data.related(ref, name, cursor) }
    scheme.register('act') { |name, ref, arguments| @actions.call(name, ref, arguments) }
    install_agent_functions
  end

  def install_agent_functions
    scheme.register('reason') { |data, task, schema| ask(task, input: data, schema: schema, tools: false) }
    scheme.register('delegate') { |data, task, schema| delegate(data, task, schema) }
    scheme.register('map-agent') { |items, task, schema| items.map { |item| delegate(item, task, schema) } }
    scheme.register('receipts') { receipts }
  end

  def delegate(input, task, schema)
    raise Captain::Apropos::Error, 'Delegation depth exceeded' if @depth >= MAX_DELEGATION_DEPTH

    child = self.class.new(account: account, user: user, execution: { budget: @budget, depth: @depth + 1 },
                           on_event: lambda { |event|
                             events << event
                             @on_event&.call(event)
                           })
    result = child.ask(task, input: input, schema: schema)
    { 'input' => input, 'status' => 'completed', 'result' => result, 'receipts' => child.receipts }
  rescue StandardError => e
    { 'input' => input, 'status' => 'failed', 'error' => e.message, 'receipts' => child ? child.receipts : [] }
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
