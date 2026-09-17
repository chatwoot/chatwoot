class Captain::Apropos::DataAccess
  PAGE_SIZE = 50

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def search(type, filters = {}, cursor = 0)
    definition = Captain::Apropos::ResourceCatalog.fetch(type.to_s)
    relation = scope(type.to_s)
    filters.each do |key, value|
      relation = apply_filter(relation, definition, key.to_s, value)
    end
    page(relation, type.to_s, cursor)
  end

  def install(scheme)
    scheme.register('search') { |type, filters = {}, cursor = 0| search(type, filters, cursor) }
    scheme.register('fetch') { |ref| fetch(ref) }
    scheme.register('related') { |ref, name, cursor = 0| related(ref, name, cursor) }
    scheme.register('assignment-context') { |ref, cursor = 0| Captain::Apropos::AssignmentContext.new(data: self).call(ref, cursor) }
  end

  def fetch(reference)
    type = reference.fetch('type')
    serialize(resolve(reference), type)
  end

  def related(reference, relationship, cursor = 0)
    record = resolve(reference)
    type, foreign_key, cardinality = Captain::Apropos::ResourceCatalog.fetch(reference.fetch('type')).fetch(:relations).fetch(relationship.to_s)
    return polymorphic_page(record, type, foreign_key, cursor) if cardinality == :polymorphic

    relation = scope(type)
    relation = case cardinality
               when :many then relation.where(foreign_key => record.id)
               when :one then relation.where(id: record[foreign_key])
               when :scoped then relation.where(id: record.public_send(foreign_key).map(&:id))
               when :association then relation.where(id: associated_ids(record, foreign_key))
               else raise Captain::Apropos::Error, "Unsupported relationship cardinality: #{cardinality}"
               end
    page(relation, type, cursor)
  end

  def resolve(reference)
    scope(reference.fetch('type')).find(reference.fetch('id'))
  end

  def scope(type)
    Captain::Apropos::Access.check!(@account, @user)
    case type
    when 'contact_notes', 'assistants' then @account.public_send({ 'contact_notes' => :notes, 'assistants' => :captain_assistants }.fetch(type))
    when 'accounts' then Account.where(id: @account.id)
    when 'agents' then @account.users
    when 'faqs' then Captain::AssistantResponse.where(account_id: @account.id).approved
    when 'articles' then @account.articles.published
    when 'contacts', 'conversations', 'messages', 'inboxes', 'teams', 'labels' then @account.public_send(type)
    else raise Captain::Apropos::Error, "Unknown entity: #{type}"
    end
  end

  private

  def associated_ids(record, name)
    association = record.association(name).scope
    association.reselect(association.klass.arel_table[:id])
  end

  def polymorphic_page(record, targets, name, cursor)
    association = record.class.reflect_on_association(name.to_sym)
    sender_type = record[association.foreign_type]
    return { 'kind' => 'record_page', 'items' => [], 'item_count' => 0, 'has_more' => false, 'next_cursor' => false } if sender_type.nil?

    type = targets.fetch(sender_type) { raise Captain::Apropos::Error, "Related #{name} type is not an exposed resource: #{sender_type}" }
    page(scope(type).where(id: record[association.foreign_key]), type, cursor)
  end

  def apply_filter(relation, definition, key, value)
    return relation.tagged_with(Array(value)) if key == 'labels' && relation.klass == Conversation

    if key == 'query'
      columns = definition.fetch(:query)
      raise Captain::Apropos::Error, 'This entity has no text query; use field filters or follow messages' if columns.empty?

      pattern = "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"
      clauses = columns.map { |column| "#{relation.klass.quoted_table_name}.#{relation.klass.connection.quote_column_name(column)} ILIKE :query" }
      return relation.where(clauses.join(' OR '), query: pattern)
    end
    raise Captain::Apropos::Error, "Unsupported filter: #{key}" unless definition.fetch(:fields).include?(key)

    relation.where(key => value)
  end

  def page(relation, type, cursor)
    cursor = Integer(cursor)
    raise Captain::Apropos::Error, 'Cursor must be nonnegative' if cursor.negative?

    records = relation.where("#{relation.klass.quoted_table_name}.id > ?", cursor).reorder(id: :asc).limit(PAGE_SIZE + 1).to_a
    { 'kind' => 'record_page', 'items' => records.first(PAGE_SIZE).map { |record| serialize(record, type) },
      'item_count' => [records.size, PAGE_SIZE].min, 'has_more' => records.size > PAGE_SIZE,
      'next_cursor' => records.size > PAGE_SIZE ? records[PAGE_SIZE - 1].id : false }
  end

  def serialize(record, type)
    fields = Captain::Apropos::ResourceFields.for(type)
    record.attributes.slice(*fields).as_json.merge('ref' => { 'type' => type, 'id' => record.id })
  end
end
