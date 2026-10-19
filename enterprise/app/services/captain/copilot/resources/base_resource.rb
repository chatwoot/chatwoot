# A resource declares:
#   NAME         the value the model passes to get_data
#   DATE_FIELDS  the columns that since, before and newest use; the first one is the default
#   FILTERS      JSON schema properties for its own filters
#   SOURCES      { saved set resource => lambda taking record IDs and returning this resource's linked records }
#   COLUMNS      display headers after the first column, which links to the record
#   PRELOAD      associations row(record) reads, loaded once per display page
#   GROUPS       values get_data can count records by, besides periods of the date field
# and implements scope (the records the user may see), filter(scope, filters), row(record) for display and
# counts_by(relation, group) for GROUPS.
class Captain::Copilot::Resources::BaseResource
  include Captain::Copilot::ConversationAccess

  PERIODS = { 'day' => '%Y-%m-%d', 'week' => 'week of %Y-%m-%d', 'month' => '%Y-%m', 'year' => '%Y' }.freeze
  MAX_GROUPS = 100

  # newest is only for a number the agent states, e.g. "the last 20 conversations". A generic limit let the model cap
  # selections the agent asked for in full, so without newest Ruby selects everything up to MAX_SELECTION.
  COMMON_FILTERS = {
    since: { type: 'string', format: 'date-time' }, before: { type: 'string', format: 'date-time' },
    newest: { type: 'integer', minimum: 1, maximum: CopilotRun::MAX_SELECTION, description: 'The number of most recent records by date_field' }
  }.freeze

  def self.filter_schema
    properties = COMMON_FILTERS.merge(date_field: { type: 'string', enum: self::DATE_FIELDS }).merge(self::FILTERS)
    { type: 'object', additionalProperties: false, properties: properties }.deep_stringify_keys
  end

  def self.help
    "- #{self::NAME}: filters #{filters_help}. Group by: #{group_options.join(', ')}. Can start from: #{self::SOURCES.keys.join(', ')}"
  end

  def self.group_options
    PERIODS.keys + self::GROUPS
  end

  # Lists allowed values and descriptions, so the model does not have to guess them.
  def self.filters_help
    filter_schema['properties'].map do |name, property|
      allowed = property['enum'] || property.dig('items', 'enum')
      detail = allowed ? allowed.map { |value| value || 'null' }.join(' or ') : property['description']
      detail ? "#{name} (#{detail})" : name
    end.join(', ')
  end

  # A fact about the selection the agent must hear, such as a date range normalize chose because none was given.
  attr_reader :note

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  # Resources that need more than the filters, such as the saved set a selection starts from, take it as a keyword.
  def normalize(filters, **)
    filters = filters.deep_stringify_keys
    unless JSONSchemer.schema(self.class.filter_schema).valid?(filters)
      raise ArgumentError, "Invalid #{self.class::NAME} filters. Allowed: #{self.class.filters_help}"
    end

    filters.reverse_merge('date_field' => self.class::DATE_FIELDS.first)
  end

  # The visible records that match the filters and, when a source set is given, are linked to its records.
  def matching(filters, as_of:, source: nil)
    relation = scope
    relation = relation.where(id: linked(source).select(:id)) if source
    filter(apply_dates(relation, filters, as_of), filters).reorder(nil)
  end

  # Newest first by the date field, because reviews work through a selection in order. With newest, that many records;
  # otherwise up to one more than MAX_SELECTION, so the caller can tell when the selection was cut.
  def selected_ids(relation, filters)
    table = relation.klass.arel_table
    relation.reorder(table[filters['date_field']].desc.nulls_last, table[:id].desc)
            .limit(filters['newest'] || (CopilotRun::MAX_SELECTION + 1)).pluck(:id)
  end

  # Counts per period or value, computed by the database so the model never tallies rows itself. Periods are UTC and
  # include empty ones within since and before.
  def group_counts(relation, filters, as_of, group)
    raise ArgumentError, "group_by must be one of: #{self.class.group_options.join(', ')}" unless self.class.group_options.include?(group)

    counts = if PERIODS.key?(group)
               period_counts(relation, filters, as_of, group)
             else
               counts_by(relation, group).sort_by { |_, count| -count }.to_h
             end
    raise ArgumentError, "group_by #{group} gives #{counts.size} groups. Use a larger period or narrower filters." if counts.size > MAX_GROUPS

    counts.map { |value, count| { group: value, count: count } }
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
  # that were never active, and the query already runs at as_of.
  def apply_dates(relation, filters, as_of)
    return relation unless filters['since'] || filters['before']

    since, before = date_range(filters, as_of)
    field = relation.klass.arel_table[filters['date_field']]
    relation = relation.where(field.lt(before))
    since ? relation.where(field.gteq(since)) : relation
  end

  def date_range(filters, as_of)
    since = Time.iso8601(filters['since']) if filters['since']
    before = filters['before'] ? Time.iso8601(filters['before']) : as_of
    raise ArgumentError, 'since must be earlier than before' if since && since >= before
    raise ArgumentError, 'before cannot be in the future' if before > as_of

    [since, before]
  end

  def period_counts(relation, filters, as_of, period)
    field = filters['date_field']
    options = { time_zone: 'UTC' }
    options[:week_start] = :monday if period == 'week'
    options[:range] = Range.new(*date_range(filters, as_of), true) if filters['since']
    counts = relation.where.not(field => nil).group_by_period(period, field, **options).count
    counts = counts.transform_keys { |date| date.strftime(PERIODS.fetch(period)) }
    undated = relation.where(field => nil).count
    undated.positive? ? counts.merge('No date' => undated) : counts
  end

  # Counts a column's values, naming IDs by the records they point to, e.g. an inbox's name instead of its ID. Records
  # with no value, such as conversations without an assignee, are counted as None.
  def column_counts(relation, column, names: nil)
    counts = relation.group(column).count
    named = names ? names.where(id: counts.keys.compact).to_h { |record| [record.id, "#{record.name} (ID #{record.id})"] } : {}
    counts.transform_keys { |key| key.nil? ? 'None' : named.fetch(key) { key.to_s } }
  end

  # A record with several labels counts once for each of them.
  def label_counts(relation)
    taggings = ActsAsTaggableOn::Tagging.where(taggable_type: relation.klass.name, context: 'labels')
    counts = taggings.where(taggable_id: relation.select(:id)).joins(:tag).group('tags.name').count
    unlabeled = relation.where.not(id: taggings.select(:taggable_id)).count
    unlabeled.positive? ? counts.merge('No label' => unlabeled) : counts
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
