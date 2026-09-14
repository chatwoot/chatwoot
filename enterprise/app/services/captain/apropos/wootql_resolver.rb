# Scans originate here, from server-owned scopes. WootQL cannot supply a scan
# or remove its scope. Scheme only submits source text, never a resolved plan.
class Captain::Apropos::WootqlResolver
  include Captain::Apropos::WootqlTypes

  Field = Captain::Apropos::WootqlSchema::Field
  Plan = Struct.new(:operation, :input, :options, :fields, :order, keyword_init: true)
  MAX_JOINS = 8
  MAX_FIELDS = 100
  MAX_LIMIT = 100_000
  MAX_PARAMETER_BYTES = 32_768
  MAX_DURATION_SECONDS = 100 * 365 * 86_400
  STAGES = { 'where' => :filter, 'project' => :project, 'join' => :explicit_join, 'summarize' => :summarize, 'sort' => :sort,
             'take' => :limit }.freeze
  DURATION_SECONDS = { 'ms' => 0.001, 's' => 1, 'm' => 60, 'h' => 3600, 'd' => 86_400, 'w' => 604_800 }.freeze
  AGGREGATES = %w[count count_distinct sum avg min max].freeze

  def initialize(data:, parameters:)
    raise Captain::Apropos::Error, 'WootQL parameters must be a hash with string keys' unless parameters.is_a?(Hash) && parameters.keys.all?(String)

    raise Captain::Apropos::Error, 'WootQL parameters exceed 32 KB' if JSON.generate(parameters).bytesize > MAX_PARAMETER_BYTES

    @data = data
    @parameters = parameters
    @now = Time.current
    @origins = {}
    @joins = 0
  end

  def resolve(ast)
    @plan = scan(ast.resource)
    @origins[''] = ast.resource
    ast.stages.each { |stage| apply(stage) }
    @plan
  rescue KeyError => e
    raise Captain::Apropos::Error, "Unknown WootQL resource, relationship, field, or parameter: #{e.key}"
  end

  private

  def scan(resource)
    relation = @data.scope(resource)
    fields = Captain::Apropos::WootqlSchema.fields(resource, relation)
    Plan.new(operation: :scan, options: { relation: relation }, fields: fields, order: { 'id' => 'asc' })
  end

  def apply(stage)
    send(STAGES.fetch(stage.fetch(:operation)), stage.fetch(:arguments))
    raise Captain::Apropos::Error, 'WootQL exceeds 100 output fields; project fewer fields before joining' if @plan.fields.size > MAX_FIELDS
  rescue Captain::Apropos::Error => e
    raise e.with_feedback("Pipeline operation: #{stage.fetch(:operation)}.",
                          Captain::Apropos::WootqlFeedback.fields(@plan.fields),
                          context: Captain::Apropos::WootqlFeedback.stage_context(stage.fetch(:operation)))
  end

  def append(operation, options, fields: @plan.fields, order: @plan.order)
    @plan = Plan.new(operation: operation, input: @plan, options: options, fields: fields, order: order)
  end

  def field(name)
    return @plan.fields.fetch(name) if @plan.fields.key?(name)

    parts = name.split('.')
    origin(parts[0...-1].join('.')) if parts.size > 1
    @plan.fields.fetch(name) { raise Captain::Apropos::Error, "Unknown WootQL field: #{name}" }
  end

  def origin(prefix)
    return if @origins.key?(prefix)

    parts = prefix.split('.')
    parent = parts[0...-1].join('.')
    origin(parent) unless parent.empty?
    resource = @origins.fetch(parent)
    target, key, cardinality = Captain::Apropos::Catalog::ENTITIES.fetch(resource).fetch(:relations).fetch(parts.last)
    raise Captain::Apropos::Error, 'Scoped relationships require Scheme related, not WootQL' if cardinality == :scoped
    raise Captain::Apropos::Error, 'To-many paths require an explicit join before aggregation' unless cardinality == :one

    left = [parent.presence, key].compact.join('.')
    join(scan(target), left, 'id', prefix, 'left')
    @origins[prefix] = target
  end

  def explicit_join(args)
    prefix = args.fetch(:prefix)
    validate_name!(prefix)
    raise Captain::Apropos::Error, "Join alias already in use: #{prefix}" if @origins.key?(prefix)

    field(args.fetch(:left))
    right_name = args.fetch(:right)
    unless right_name.start_with?("#{prefix}.")
      raise Captain::Apropos::Error, 'The right join field must start with the join alias, such as contact.id'
    end

    right = scan(args.fetch(:resource))
    join(right, args.fetch(:left), right_name.delete_prefix("#{prefix}."), prefix, args.fetch(:kind))
    @origins[prefix] = args.fetch(:resource)
  end

  def join(right, left_name, right_name, prefix, kind)
    @joins += 1
    raise Captain::Apropos::Error, 'WootQL exceeds 8 joins' if @joins > MAX_JOINS

    left_type = @plan.fields.fetch(left_name).type
    right_type = right.fields.fetch(right_name).type
    raise Captain::Apropos::Error, 'Join field types do not match' unless compatible_types?(left_type, right_type)

    renamed = join_fields(right, prefix)
    order = @plan.order.merge(right.order.transform_keys { |name| "#{prefix}.#{name}" })
    append(:join, { right: right, left_field: left_name, right_field: right_name, prefix: prefix, kind: kind },
           fields: @plan.fields.merge(renamed), order: order)
  end

  def join_fields(right, prefix)
    renamed = right.fields.transform_keys { |name| "#{prefix}.#{name}" }
    renamed.each_key { |name| validate_name!(name) }
    raise Captain::Apropos::Error, 'Join would overwrite an existing field' if @plan.fields.keys.intersect?(renamed.keys)

    renamed
  end

  def filter(predicate)
    append(:filter, resolve_predicate(predicate))
  end

  def resolve_predicate(predicate)
    operator = predicate.fetch(:operator)
    case operator
    when 'and', 'or'
      predicate.merge(left: resolve_predicate(predicate.fetch(:left)), right: resolve_predicate(predicate.fetch(:right)))
    when 'not'
      predicate.merge(expression: resolve_predicate(predicate.fetch(:expression)))
    else
      column = field(predicate.fetch(:field))
      return predicate if %w[is_null is_not_null].include?(operator)

      return resolve_emptiness(predicate, column) if %w[is_empty is_not_empty].include?(operator)

      resolve_comparison(predicate, column)
    end
  end

  def project(projections)
    unique_names!(projections.map { |item| item.fetch(:name) })
    fields = projections.to_h { |item| [item.fetch(:name), field(item.fetch(:field))] }
    mapping = projections.to_h { |item| [item.fetch(:name), item.fetch(:field)] }
    order = @plan.order.filter_map { |name, direction| [mapping.key(name), direction] if mapping.value?(name) }.to_h
    append(:project, mapping, fields: fields, order: order)
    @origins.clear
  end

  def summarize(args)
    keys = args.fetch(:keys)
    aggregates = args.fetch(:aggregates)
    unique_names!(keys + aggregates.map { |item| item.fetch(:name) })
    fields = keys.index_with { |name| field(name) }
    fields.each_value { |definition| require_ordered!(definition) }
    aggregates.each { |item| fields[item.fetch(:name)] = aggregate_type(item) }
    append(:summarize, args, fields: fields, order: keys.index_with { 'asc' })
    @origins.clear
  end

  def aggregate_type(item)
    function = item.fetch(:function)
    raise Captain::Apropos::Error, "Unknown WootQL aggregate: #{function}" unless AGGREGATES.include?(function)

    if item.fetch(:field).nil?
      raise Captain::Apropos::Error, 'Only count() can omit its field' unless function == 'count'

      return Field.new(type: :integer)
    end

    definition = field(item.fetch(:field))
    require_ordered!(definition)
    require_numeric!(definition) if %w[sum avg].include?(function)
    return Field.new(type: :integer) if %w[count count_distinct].include?(function)

    function == 'avg' ? Field.new(type: :decimal) : definition
  end

  def sort(items)
    unique_names!(items.map { |item| item.fetch(:field) }, label: 'sort fields')
    items.each { |item| require_ordered!(field(item.fetch(:field))) }
    order = items.to_h { |item| [item.fetch(:field), item.fetch(:direction)] }
    append(:sort, {}, order: order.merge(@plan.order.except(*order.keys)))
  end

  def limit(expression)
    count = literal(expression)
    raise Captain::Apropos::Error, 'take requires an integer between 0 and 100000' unless count.is_a?(Integer) && count.between?(0, MAX_LIMIT)

    append(:limit, { count: count })
  end

  def literal(expression)
    return expression.fetch(:literal) if expression.key?(:literal)

    if expression.key?(:parameter)
      return @parameters.fetch(expression.fetch(:parameter)) do
        raise Captain::Apropos::Error, "Missing WootQL parameter: $#{expression[:parameter]}"
      end
    end
    return @now if expression.key?(:now)

    duration = expression.fetch(:ago).match(/\A(\d+)(ms|s|m|h|d|w)\z/)
    seconds = duration[1].to_i * DURATION_SECONDS.fetch(duration[2])
    raise Captain::Apropos::Error, 'Relative duration cannot exceed 100 years' if seconds > MAX_DURATION_SECONDS

    @now - seconds
  end

  def unique_names!(names, label: 'output names')
    raise Captain::Apropos::Error, "WootQL #{label} must be unique" unless names.uniq == names

    names.each { |name| validate_name!(name) }
  end

  def validate_name!(name)
    return if name.bytesize <= 63

    raise Captain::Apropos::Error, 'WootQL field names must be at most 63 bytes'
  end
end
