class Captain::Apropos::Query
  PAGE_SIZE = 200
  MAX_CALLS = 100
  MAX_OFFSET = 100_000
  TIMEOUT_MS = 5_000

  def initialize(data:, budget:, instrument: nil)
    @data = data
    @budget = budget
    @instrument = instrument
  end

  def run(source, parameters = {}, offset = 0, debug: false)
    validate_offset!(offset)
    @budget[:queries] += 1
    with_stage('request validation') { raise Captain::Apropos::Error, 'Query call budget exhausted' if @budget[:queries] > MAX_CALLS }

    attributes = { 'wootql.source' => source, 'wootql.offset' => offset, 'wootql.parameter_names' => parameters.keys.map(&:to_s).sort }
    instrument('query', attributes) { |span| run_pipeline(source, parameters, offset, debug, span) }
  end

  private

  def run_pipeline(source, parameters, offset, debug, query_span)
    ast = with_stage('parsing') do
      instrument('parse', { 'wootql.source_bytes' => source.to_s.bytesize }) { Captain::Apropos::WootqlParser.new(source).parse }
    end
    plan = with_stage('resolution') do
      instrument('resolve', { 'wootql.resource' => ast.resource }) do
        Captain::Apropos::WootqlResolver.new(data: @data, parameters: parameters).resolve(ast)
      end
    end
    result = with_stage('compilation and database execution') do
      instrument('execute', { 'wootql.offset' => offset, 'wootql.fields' => plan.fields.keys }) { page(plan, offset, debug) }
    end
    Captain::Apropos::Instrumentation.set_attributes(query_span, {
                                                       'wootql.row_count' => result.fetch('items').size,
                                                       'wootql.has_next_page' => (result.fetch('next_offset') != false)
                                                     })
    result
  end

  def validate_offset!(offset)
    return if offset.is_a?(Integer) && offset.between?(0, MAX_OFFSET)

    with_stage('request validation') { raise Captain::Apropos::Error, "Query offset must be an integer between 0 and #{MAX_OFFSET}" }
  end

  def with_stage(stage)
    yield
  rescue Captain::Apropos::Error => e
    facts = ["Query stage: #{stage}."]
    facts << 'This query did not reach SQL execution.' unless stage == 'compilation and database execution'
    raise e.with_feedback(*facts)
  end

  def instrument(stage, attributes, &)
    return yield unless @instrument

    @instrument.call(stage, attributes, &)
  end

  def page(plan, offset, debug)
    ApplicationRecord.with_connection do |connection|
      compiler = Captain::Apropos::QueryCompiler.new(connection: connection)
      sql = "#{compiler.compile(plan)} LIMIT #{PAGE_SIZE + 1} OFFSET #{offset}"
      # SET LOCAL is transaction-scoped; roll back the read-only savepoint to restore
      # the caller's timeout even when query-run runs inside another transaction.
      # https://www.postgresql.org/docs/current/sql-set.html
      rows = execute(connection, sql, compiler.binds)
      result = { 'items' => rows.first(PAGE_SIZE).as_json, 'next_offset' => rows.size > PAGE_SIZE ? offset + PAGE_SIZE : false }
      result.merge!('sql' => sql, 'binds' => compiler.binds.map(&:value_before_type_cast), 'columns' => plan.fields.keys) if debug
      result
    end
  end

  def execute(connection, sql, binds)
    result = nil
    connection.transaction(requires_new: true) do
      connection.execute("SET LOCAL statement_timeout = #{TIMEOUT_MS}")
      raw = connection.select_all(sql, 'Apropos query', binds)
      # Use adapter types rather than exposing PostgreSQL array literals to Scheme.
      # https://github.com/rails/rails/blob/v7.2.3.1/activerecord/lib/active_record/result.rb
      result = raw.cast_values.map { |row| raw.columns.zip(raw.columns.one? ? [row] : row).to_h }
      raise ActiveRecord::Rollback
    end
    result
  rescue ActiveRecord::StatementInvalid => e
    raise Captain::Apropos::Error.new('WootQL database execution failed').with_feedback(
      "Database exception: #{e.cause.class.name}.", "Statement timeout: #{TIMEOUT_MS} milliseconds.",
      context: ['The query produced no result page. A database failure does not establish that the matching dataset is empty.']
    )
  end
end
