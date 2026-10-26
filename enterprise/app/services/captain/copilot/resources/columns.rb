# The columns of a model Copilot may read, as listed in enterprise/config/copilot_tables.yml. A key inside a listed JSON
# column is a field too, written column.key, such as additional_attributes.country.
module Captain::Copilot::Resources::Columns
  TABLES = YAML.load_file(Rails.root.join('enterprise/config/copilot_tables.yml')).freeze
  # Settings shown whole, such as an automation rule's actions, drop keys with these names as a last check.
  SECRET_KEY = /(\A|_)(token|secret|password|key|credential|otp|salt|digest|certificate)s?(_|\z)/
  DATE_TYPES = %i[datetime date].freeze
  NUMBER_TYPES = %i[integer float decimal].freeze
  # describe lists the keys found in at most this many JSON values, and at most MAX_KEYS of them.
  KEY_SAMPLE = 1000
  MAX_KEYS = 40

  def self.listed?(model)
    TABLES.key?(model.table_name)
  end

  # id and the listed columns, in the table's own order.
  def self.readable(model)
    names = ['id'] + TABLES.fetch(model.table_name).fetch('columns')
    model.columns.select { |column| names.include?(column.name) }
  end

  def self.names(model, types = nil)
    columns = readable(model)
    columns = columns.select { |column| types.include?(column.type) } if types
    columns.map(&:name)
  end

  # Enums are stored as numbers, but their codes are not quantities, so they are left out.
  def self.numbers(model)
    names(model, NUMBER_TYPES) - model.defined_enums.keys
  end

  def self.json(model)
    TABLES.fetch(model.table_name).fetch('json', [])
  end

  # created_at first, so it is the default date when a resource names none.
  def self.dates(model)
    names(model, DATE_TYPES).sort_by { |name| name == 'created_at' ? 0 : 1 }
  end

  # Filters every resource takes on its own fields: which must have no value or a value, bounds on numbers, and the
  # value of a key inside a JSON column. empty and not_empty take columns, keys inside JSON columns, and the names of the
  # resources that point at the model, given as links.
  def self.operators(model, links = [])
    bounds = { type: 'object', propertyNames: { enum: numbers(model) }, additionalProperties: { type: 'number' } }
    operators = { empty: fields(model, links), not_empty: fields(model, links), at_least: bounds, at_most: bounds }
    return operators if json(model).empty?

    operators.merge(attributes: { type: 'object', propertyNames: json_path(model),
                                  additionalProperties: { type: %w[string number boolean null] } })
  end

  def self.fields(model, links)
    names = { type: 'string', enum: names(model) + links }
    { type: 'array', minItems: 1, items: json(model).empty? ? names : { type: 'string', anyOf: [names.except(:type), json_path(model)] } }
  end

  def self.json_path(model)
    { pattern: "^(#{json(model).join('|')})\\.[^.]+$" }
  end

  # Equality filters by value. Text is not filtered by value, and dates use since and before.
  def self.filters(model)
    readable(model).filter_map do |column|
      next if column.type == :text || DATE_TYPES.include?(column.type) || column.name == 'id'

      [column.name.to_sym, schema_for(model, column)]
    end.to_h
  end

  def self.schema_for(model, column)
    enum = model.defined_enums[column.name]
    if enum then { type: %w[string null], enum: enum.keys + [nil] }
    elsif column.type == :boolean then { type: 'boolean' }
    elsif NUMBER_TYPES.include?(column.type) then { type: %w[number null] }
    else
      { type: %w[string null] }
    end
  end

  # The column filters every resource shares. Links in empty and not_empty are the resource's to apply.
  def self.apply(relation, filters, equality)
    apply_values(apply_presence(relation.where(filters.slice(*equality)), filters), filters)
  end

  # Each field is its own condition. A JSON key is empty when the record does not have it or it is null.
  def self.apply_presence(relation, filters)
    empty = Array(filters['empty']).filter_map { |name| presence_field(relation.klass, name) }
    not_empty = Array(filters['not_empty']).filter_map { |name| presence_field(relation.klass, name) }
    relation = empty.reduce(relation) { |scope, field| scope.where(field.eq(nil)) }
    not_empty.reduce(relation) { |scope, field| scope.where(field.not_eq(nil)) }
  end

  # The fields the filters rely on that no record in relation has a value for, such as a date column nobody fills or a
  # JSON key no record uses, so the agent does not read an empty or full selection as an answer.
  def self.unused(relation, filters)
    fields = Array(filters['empty']) + Array(filters['not_empty']) + filters.fetch('attributes', {}).keys
    fields << filters['date_field'] if filters['since'] || filters['before']
    fields.uniq.select { |name| (field = presence_field(relation.klass, name)) && !relation.where(field.not_eq(nil)).exists? }
  end

  # A column or a key inside a JSON column, or nil for a link, which the resource applies.
  def self.presence_field(model, name)
    if name.include?('.') then json_field(model, name)
    elsif names(model).include?(name) then model.arel_table[name]
    end
  end

  # Bounds on numbers, and a JSON key, which compares as text, the way the database returns it.
  def self.apply_values(relation, filters)
    table = relation.klass.arel_table
    relation = filters.fetch('at_least', {}).reduce(relation) { |scope, (column, value)| scope.where(table[column].gteq(value)) }
    relation = filters.fetch('at_most', {}).reduce(relation) { |scope, (column, value)| scope.where(table[column].lteq(value)) }
    filters.fetch('attributes', {}).reduce(relation) { |scope, (path, value)| scope.where(json_field(relation.klass, path).eq(value&.to_s)) }
  end

  # A key inside a JSON column, written column.key, as a database expression.
  def self.json_field(model, path)
    column, key = path.split('.', 2)
    raise ArgumentError, "#{path} is not a key of a readable JSON column" unless json(model).include?(column) && key.present?

    Arel::Nodes::InfixOperation.new('->>', model.arel_table[column], Arel::Nodes.build_quoted(key))
  end

  # The top-level keys the records use in a JSON column, so the model can discover fields no one listed.
  def self.json_keys(relation, column)
    function = relation.klass.columns_hash[column].type == :jsonb ? 'jsonb' : 'json'
    value = relation.klass.arel_table[column]
    objects = relation.where(Arel::Nodes::NamedFunction.new("#{function}_typeof", [value]).eq('object'))
    objects.limit(KEY_SAMPLE).pluck(Arel::Nodes::NamedFunction.new("#{function}_object_keys", [value])).uniq.first(MAX_KEYS)
  end

  # A JSON value as compact text with secret-named keys removed, for display.
  def self.without_secrets(value)
    case value
    when Hash then value.reject { |key, _| key.to_s.match?(SECRET_KEY) }.transform_values { |item| without_secrets(item) }
    when Array then value.map { |item| without_secrets(item) }
    else value
    end
  end
end
