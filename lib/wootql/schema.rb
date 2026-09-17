class Wootql::Schema
  Field = Struct.new(:type, :enum_values, :expression, keyword_init: true)

  def relations(resource)
    Captain::Apropos::ResourceCatalog.fetch(resource).fetch(:relations)
  end

  def describe(data)
    Captain::Apropos::ResourceCatalog.entries.to_h do |resource, definition|
      columns = fields(resource, data.scope(resource)).transform_values do |field|
        { type: field.type, values: field.enum_values&.keys }.compact
      end
      relations = definition.fetch(:relations).select { |_, (_, _, cardinality)| %i[one many].include?(cardinality) }
      [resource, { fields: columns, relations: relations, description: definition[:description] }.compact]
    end
  end

  def fields(resource, relation)
    definition = Captain::Apropos::ResourceCatalog.fetch(resource)
    fields = definition.fetch(:fields).index_with do |name|
      values = relation.klass.defined_enums[name]
      Field.new(type: values ? :string : relation.klass.type_for_attribute(name).type, enum_values: values)
    end
    definition.fetch(:query_fields, {}).each do |name, type|
      fields[name] = Field.new(type: type, expression: expression(resource, name))
    end
    fields
  end

  def expression(resource, name)
    raise Wootql::Error, "Unknown computed query field: #{resource}.#{name}" unless resource == 'conversations' && name == 'labels'

    # Use the same label membership expression as the existing Chatwoot engine,
    # so discovery and execution cannot disagree about what this field means.
    Captain::Apropos::WootqlSchema.expression(resource, name)
  end
end
