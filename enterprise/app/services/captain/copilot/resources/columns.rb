# The readable columns of the tables in enterprise/config/copilot_tables.yml, and the filters every resource takes on them.
module Captain::Copilot::Resources::Columns
  TABLES = YAML.load_file(Rails.root.join('enterprise/config/copilot_tables.yml')).freeze
  SCALAR_TYPES = %i[integer float decimal string text boolean datetime date].freeze
  JSON_TYPES = %i[json jsonb].freeze
  DATE_TYPES = %i[datetime date].freeze
  NUMBER_TYPES = %i[integer float decimal].freeze
  # Keys with these names inside JSON columns are never read, listed or shown, as a last check after the exclusions.
  SECRET_KEY = /(\A|_)(token|secret|password|key|credential|otp|salt|digest|certificate)s?(_|\z)/
  # describe lists the keys found in at most this many JSON values, and at most MAX_KEYS of them.
  KEY_SAMPLE = 1000
  MAX_KEYS = 40

  def self.readable(model)
    allowed(model, SCALAR_TYPES)
  end

  def self.json(model)
    allowed(model, JSON_TYPES).map(&:name)
  end

  def self.allowed(model, types)
    excluded = excluded(model)
    model.columns.select { |column| types.include?(column.type) && excluded.exclude?(column.name) }
  end

  def self.excluded(model)
    polymorphic = model.reflect_on_all_associations(:belongs_to).select(&:polymorphic?).flat_map { |link| [link.foreign_key, link.foreign_type] }
    ['account_id', *polymorphic.map(&:to_s), *Array(model.encrypted_attributes).map(&:to_s), *TABLES.fetch(model.table_name).fetch('exclude', [])]
  end

  def self.names(model, types = SCALAR_TYPES)
    readable(model).select { |column| types.include?(column.type) }.map(&:name)
  end

  # Enums are stored as numbers, but their codes are not quantities, so they are left out.
  def self.numbers(model)
    names(model, NUMBER_TYPES) - model.defined_enums.keys
  end

  # created_at first, so it is the default date when a resource names none.
  def self.dates(model)
    names(model, DATE_TYPES).sort_by { |name| name == 'created_at' ? 0 : 1 }
  end

  # links are the names of the resources that point at the model, which empty and not_empty also take.
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

  def self.apply(relation, filters, equality)
    apply_values(apply_presence(relation.where(filters.slice(*equality)), filters), filters)
  end

  # A JSON key is empty when the record does not have it or it is null.
  def self.apply_presence(relation, filters)
    empty = Array(filters['empty']).filter_map { |name| presence_field(relation.klass, name) }
    not_empty = Array(filters['not_empty']).filter_map { |name| presence_field(relation.klass, name) }
    relation = empty.reduce(relation) { |scope, field| scope.where(field.eq(nil)) }
    not_empty.reduce(relation) { |scope, field| scope.where(field.not_eq(nil)) }
  end

  # The fields no record has a value for, so the agent does not read an empty or full selection as an answer.
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

  # A JSON key compares as text, the way ->> returns it.
  def self.apply_values(relation, filters)
    table = relation.klass.arel_table
    relation = filters.fetch('at_least', {}).reduce(relation) { |scope, (column, value)| scope.where(table[column].gteq(value)) }
    relation = filters.fetch('at_most', {}).reduce(relation) { |scope, (column, value)| scope.where(table[column].lteq(value)) }
    filters.fetch('attributes', {}).reduce(relation) { |scope, (path, value)| scope.where(json_field(relation.klass, path).eq(value&.to_s)) }
  end

  def self.json_field(model, path)
    column, key = path.split('.', 2)
    readable = json(model).include?(column) && key.present? && !key.match?(SECRET_KEY)
    raise ArgumentError, "#{path} is not a key of a readable JSON column" unless readable

    Arel::Nodes::InfixOperation.new('->>', model.arel_table[column], Arel::Nodes.build_quoted(key))
  end

  def self.json_keys(relation, column)
    function = relation.klass.columns_hash[column].type == :jsonb ? 'jsonb' : 'json'
    value = relation.klass.arel_table[column]
    objects = relation.where(Arel::Nodes::NamedFunction.new("#{function}_typeof", [value]).eq('object'))
    keys = objects.limit(KEY_SAMPLE).pluck(Arel::Nodes::NamedFunction.new("#{function}_object_keys", [value])).uniq
    keys.grep_v(SECRET_KEY).first(MAX_KEYS)
  end
end
