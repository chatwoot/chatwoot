# Accepts resolver-created plans only. Values use bind parameters; names are
# resolved catalog columns or parsed aliases, quoted with the Rails adapter.
class Captain::Apropos::QueryCompiler
  COMPARISONS = { '=' => '=', '!=' => '<>', '>' => '>', '>=' => '>=', '<' => '<', '<=' => '<=', 'contains' => 'ILIKE' }.freeze
  AGGREGATES = { 'count' => 'COUNT', 'count_distinct' => 'COUNT', 'sum' => 'SUM', 'avg' => 'AVG', 'min' => 'MIN', 'max' => 'MAX' }.freeze
  DIRECTIONS = { 'asc' => 'ASC', 'desc' => 'DESC' }.freeze
  STAGES = { project: :project, join: :join, summarize: :summarize }.freeze

  attr_reader :binds

  def initialize(connection:)
    @connection = connection
    @binds = []
  end

  def compile(plan)
    "SELECT q.* FROM (#{node(plan)}) q#{ordering(plan.order)}"
  end

  private

  def node(plan)
    return scan(plan) if plan.operation == :scan

    input = node(plan.input)
    return send(STAGES.fetch(plan.operation), input, plan) if STAGES.key?(plan.operation)

    case plan.operation
    when :filter then "SELECT q.* FROM (#{input}) q WHERE #{predicate(plan.options)}"
    when :sort then "SELECT q.* FROM (#{input}) q#{ordering(plan.order)}"
    when :limit then "SELECT q.* FROM (#{input}) q#{ordering(plan.order)} LIMIT #{plan.options.fetch(:count)}"
    else raise Captain::Apropos::Error, 'Unknown resolved query operation'
    end
  end

  def scan(plan)
    relation = plan.options.fetch(:relation)
    table = relation.klass.quoted_table_name
    columns = plan.fields.map do |name, definition|
      column = definition.expression || "#{table}.#{identifier(name)}"
      if definition.enum_values
        cases = definition.enum_values.map { |label, value| "WHEN #{bind(value)} THEN #{bind(label)}" }.join(' ')
        column = "CASE #{column} #{cases} END"
      end
      "#{column} AS #{identifier(name)}"
    end
    relation.reorder(nil).reselect(Arel.sql(columns.join(', '))).to_sql
  end

  def predicate(expression)
    operator = expression.fetch(:operator)
    return "#{column(expression.fetch(:field))} IS NULL" if operator == 'is_null'
    return "#{column(expression.fetch(:field))} IS NOT NULL" if operator == 'is_not_null'
    return "#{bind(expression.fetch(:value))} = ANY(#{column(expression.fetch(:field))})" if operator == 'includes'

    logical_predicate(expression, operator)
  end

  def logical_predicate(expression, operator)
    case operator
    when 'and', 'or' then "(#{predicate(expression.fetch(:left))} #{operator.upcase} #{predicate(expression.fetch(:right))})"
    when 'not' then "NOT (#{predicate(expression.fetch(:expression))})"
    when 'in' then "#{column(expression.fetch(:field))} IN (#{expression.fetch(:value).map { |value| bind(value) }.join(', ')})"
    else
      value = expression.fetch(:value)
      value = "%#{ActiveRecord::Base.sanitize_sql_like(value)}%" if operator == 'contains'
      "#{column(expression.fetch(:field))} #{COMPARISONS.fetch(operator)} #{bind(value)}"
    end
  end

  def project(input, plan)
    selected = plan.options.map { |name, field| "#{column(field)} AS #{identifier(name)}" }
    "SELECT #{selected.join(', ')} FROM (#{input}) q"
  end

  def join(input, plan)
    options = plan.options
    right = options.fetch(:right)
    selected = ['q.*'] + right.fields.keys.map { |field| "r.#{identifier(field)} AS #{identifier("#{options.fetch(:prefix)}.#{field}")}" }
    condition = "#{column(options.fetch(:left_field))} = r.#{identifier(options.fetch(:right_field))}"
    kind = { 'inner' => 'INNER', 'left' => 'LEFT' }.fetch(options.fetch(:kind))
    "SELECT #{selected.join(', ')} FROM (#{input}) q #{kind} JOIN (#{node(right)}) r ON #{condition}"
  end

  def summarize(input, plan)
    keys = plan.options.fetch(:keys).map { |name| column(name) }
    selected = keys + plan.options.fetch(:aggregates).map do |item|
      function = item.fetch(:function)
      field = item.fetch(:field)
      target = field ? column(field) : '*'
      target = "DISTINCT #{target}" if function == 'count_distinct'
      "#{AGGREGATES.fetch(function)}(#{target}) AS #{identifier(item.fetch(:name))}"
    end
    sql = "SELECT #{selected.join(', ')} FROM (#{input}) q"
    keys.empty? ? sql : "#{sql} GROUP BY #{keys.join(', ')}"
  end

  def ordering(order)
    return '' if order.empty?

    columns = order.map { |field, direction| "#{column(field)} #{DIRECTIONS.fetch(direction)} NULLS LAST" }
    " ORDER BY #{columns.join(', ')}"
  end

  def column(name) = "q.#{identifier(name)}"
  def identifier(name) = @connection.quote_column_name(name)

  def bind(value)
    type = case value
           when Integer then :integer
           when Float then :float
           when TrueClass, FalseClass then :boolean
           when Time, ActiveSupport::TimeWithZone then :datetime
           else :string
           end
    attribute_type = type == :integer ? ActiveRecord::Type::Integer.new(limit: 8) : ActiveRecord::Type.lookup(type)
    binds << ActiveRecord::Relation::QueryAttribute.new("apropos_#{binds.size}", value, attribute_type)
    "$#{binds.size}"
  end
end
