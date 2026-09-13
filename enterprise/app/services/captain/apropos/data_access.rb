class Captain::Apropos::DataAccess
  PAGE_SIZE = 50

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def search(type, filters = {}, cursor = 0)
    Captain::Apropos::Access.check!(@account, @user)
    definition = Captain::Apropos::Catalog::ENTITIES.fetch(type.to_s)
    relation = scope(type.to_s)
    filters.each do |key, value|
      relation = apply_filter(relation, definition, key.to_s, value)
    end
    page(relation, type.to_s, cursor)
  end

  def fetch(reference)
    type = reference.fetch('type')
    serialize(resolve(reference), type)
  end

  def related(reference, relationship, cursor = 0)
    record = resolve(reference)
    type, foreign_key, cardinality = Captain::Apropos::Catalog::ENTITIES.fetch(reference.fetch('type'))
                                                                        .fetch(:relations).fetch(relationship.to_s)
    relation = scope(type)
    relation = cardinality == :many ? relation.where(foreign_key => record.id) : relation.where(id: record[foreign_key])
    page(relation, type, cursor)
  end

  def resolve(reference)
    Captain::Apropos::Access.check!(@account, @user)
    scope(reference.fetch('type')).find(reference.fetch('id'))
  end

  private

  def scope(type)
    case type
    when 'agents' then @account.users
    when 'faqs' then Captain::AssistantResponse.where(account_id: @account.id).approved
    when 'articles' then @account.articles.published
    when 'contacts', 'conversations', 'messages', 'inboxes', 'teams' then @account.public_send(type)
    else raise Captain::Apropos::Error, "Unknown entity: #{type}"
    end
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
    { 'items' => records.first(PAGE_SIZE).map { |record| serialize(record, type) },
      'next_cursor' => records.size > PAGE_SIZE ? records[PAGE_SIZE - 1].id : false }
  end

  def serialize(record, type)
    fields = Captain::Apropos::Catalog::ENTITIES.fetch(type).fetch(:fields)
    record.attributes.slice(*fields).as_json.merge('ref' => { 'type' => type, 'id' => record.id })
  end
end
