class Captain::Apropos::WootqlSchema
  Field = Struct.new(:type, :enum_values, :expression, keyword_init: true)

  def self.describe(data)
    Captain::Apropos::ResourceCatalog.entries.to_h do |resource, definition|
      columns = fields(resource, data.scope(resource)).transform_values do |field|
        { type: field.type, values: field.enum_values&.keys }.compact
      end
      relations = definition.fetch(:relations).select { |_, (_, _, cardinality)| %i[one many].include?(cardinality) }
      [resource, { fields: columns, relations: relations, description: definition[:description] }.compact]
    end
  end

  def self.fields(resource, relation)
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

  def self.expression(resource, name)
    raise Captain::Apropos::Error, "Unknown computed query field: #{resource}.#{name}" unless resource == 'conversations' && name == 'labels'

    # Correlate only to the authorized conversation scan, including polymorphic
    # type and label context. Cached label text is not an exact membership source.
    taggings = ActsAsTaggableOn::Tagging.arel_table
    labels = ActsAsTaggableOn::Tag.joins(:taggings)
                                  .where(taggings: { taggable_type: 'Conversation', context: 'labels' })
                                  .where(taggings[:taggable_id].eq(Conversation.arel_table[:id]))
                                  .order(:name).select(:name)
    "ARRAY(#{labels.to_sql})"
  end
end
