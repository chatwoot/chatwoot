# A resource declares:
#   NAME         the value the model passes to get_data
#   DATE_FIELDS  the columns that since and before can use; the first one is the default
#   FILTERS      JSON schema properties for its own filters
#   SOURCES      { saved set resource => lambda taking record IDs and returning this resource's linked records }
#   COLUMNS      display headers after the first column, which links to the record
#   PRELOAD      associations row(record) reads, loaded once per display page
# and implements scope (the records the user may see), filter(scope, filters) and row(record) for display.
class Captain::Copilot::Resources::BaseResource
  include Captain::Copilot::ConversationAccess

  COMMON_FILTERS = {
    since: { type: 'string', format: 'date-time' }, before: { type: 'string', format: 'date-time' },
    limit: { type: 'integer', minimum: 1, maximum: CopilotRun::MAX_SELECTION }
  }.freeze

  def self.filter_schema
    properties = COMMON_FILTERS.merge(date_field: { type: 'string', enum: self::DATE_FIELDS }).merge(self::FILTERS)
    { type: 'object', additionalProperties: false, properties: properties }.deep_stringify_keys
  end

  def self.help
    "- #{self::NAME}: filters #{filters_help}. Can start from: #{self::SOURCES.keys.join(', ')}"
  end

  # Lists allowed values for enum filters, so the model does not have to guess them.
  def self.filters_help
    filter_schema['properties'].map do |name, property|
      allowed = property['enum'] || property.dig('items', 'enum')
      allowed ? "#{name} (#{allowed.join(' or ')})" : name
    end.join(', ')
  end

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def normalize(filters)
    filters = filters.deep_stringify_keys
    unless JSONSchemer.schema(self.class.filter_schema).valid?(filters)
      raise ArgumentError, "Invalid #{self.class::NAME} filters. Allowed: #{self.class.filters_help}"
    end

    filters.reverse_merge('date_field' => self.class::DATE_FIELDS.first, 'limit' => CopilotRun::MAX_SELECTION)
  end

  # The visible records that match the filters and, when a source set is given, are linked to its records.
  def records(filters, boundary:, source: nil)
    relation = scope
    relation = relation.where(id: linked(source).select(:id)) if source
    filter(apply_dates(relation, filters, boundary), filters)
  end

  # Display rows for records the user can still see, in the order of ids.
  def rows(ids)
    found = scope.where(id: ids).includes(self.class::PRELOAD).index_by(&:id)
    ids.filter_map { |id| found[id] && row(found[id]) }
  end

  private

  def linked(source)
    link = self.class::SOURCES[source.resource]
    unless link
      raise ArgumentError,
            "#{self.class::NAME} cannot start from #{source.resource}. Possible sources: #{self.class::SOURCES.keys.join(', ')}"
    end

    link.call(source.record_ids)
  end

  # Dates apply only when asked for. A default upper bound would drop records whose date field is empty, such as contacts
  # that were never active, and the query already runs at the boundary.
  def apply_dates(relation, filters, boundary)
    return relation unless filters['since'] || filters['before']

    since, before = date_range(filters, boundary)
    field = relation.klass.arel_table[filters['date_field']]
    relation = relation.where(field.lt(before))
    since ? relation.where(field.gteq(since)) : relation
  end

  def date_range(filters, boundary)
    since = Time.iso8601(filters['since']) if filters['since']
    before = filters['before'] ? Time.iso8601(filters['before']) : boundary
    raise ArgumentError, 'since must be earlier than before' if since && since >= before
    raise ArgumentError, 'before cannot be in the future' if before > boundary

    [since, before]
  end

  def permitted?(permission)
    account_user = @account.account_users.find_by(user_id: @user.id)
    return false unless account_user
    return account_user.custom_role.permissions.include?(permission) if account_user.custom_role.present?

    true
  end

  def url(path)
    "/app/accounts/#{@account.id}/#{path}"
  end
end
