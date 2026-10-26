# A resource declares:
#   NAME         the value the model passes to get_data
#   MODEL        the ActiveRecord model it reads, listed in enterprise/config/copilot_tables.yml
#   DATE_FIELDS  its main date columns; the first one is the default date_field
#   FILTERS      JSON schema properties for filters of its own, beyond the column filters
#   SOURCES      { saved set resource => lambda taking that set's records and returning this resource's linked records }
#                for the paths that are not a plain association
#   COLUMNS      display headers after the first column, which links to the record
#   PRELOAD      associations row(record) reads, loaded once per display page
# and implements scope (the records the user may see) and row(record) for display. It may override readable? when not
# every user may read it, filter(relation, filters) for its own FILTERS, and group_field(name) for groups that are not
# a column.
#
# The listed columns give the rest, so a column added to copilot_tables.yml needs no code: an equality filter on every
# column, every date column as a date_field, the column operators, groups, and a path from every resource linked to
# this one by an association in either direction.
class Captain::Copilot::Resources::BaseResource
  include Captain::Copilot::ConversationAccess

  # newest is only for a number the agent states, e.g. "the last 20 conversations". A generic limit let the model cap
  # selections the agent asked for in full, so without newest Ruby selects everything up to MAX_SELECTION.
  COMMON_FILTERS = {
    since: { type: 'string', format: 'date-time' }, before: { type: 'string', format: 'date-time' },
    newest: { type: 'integer', minimum: 1, maximum: CopilotRun::MAX_SELECTION, description: 'The number of records to select by date_field' },
    oldest_first: { type: 'boolean', description: 'Select and review the oldest records by date_field first' },
    sample: { type: 'integer', minimum: 1, maximum: CopilotRun::MAX_SELECTION, description: 'Select this many records spread evenly by date_field' }
  }.freeze
  # Filters every resource takes on its own columns. get_data's description explains them once for all resources.
  COLUMN_OPERATORS = %w[empty not_empty at_least at_most attributes].freeze
  GROUPS = [].freeze

  def self.filter_schema
    @filter_schema ||= begin
      operators = Captain::Copilot::Resources::Columns.operators(self::MODEL, owners.keys)
      properties = COMMON_FILTERS.merge(date_field: { type: 'string', enum: date_fields }).merge(column_filters, operators, self::FILTERS)
      { type: 'object', additionalProperties: false, properties: properties }.deep_stringify_keys
    end
  end

  # The resources that point at this one, for empty and not_empty.
  def self.owners
    @owners ||= Captain::Copilot::Resources::Links.owners(self::MODEL)
  end

  # The hand-written date fields first, so the default stays the same, then every other date column.
  def self.date_fields
    (self::DATE_FIELDS + Captain::Copilot::Resources::Columns.dates(self::MODEL)).uniq
  end

  # Equality filters on the listed columns the resource does not filter by hand.
  def self.column_filters
    Captain::Copilot::Resources::Columns.filters(self::MODEL).except(*self::FILTERS.keys)
  end

  # The saved sets a selection can start from: the paths written by hand, then every resource linked to this one.
  def self.sources
    @sources ||= Captain::Copilot::Resources.all.each_with_object(self::SOURCES.merge(self::NAME => ->(records) { records })) do |other, paths|
      path = Captain::Copilot::Resources::Links.path(self::MODEL, other::MODEL) unless paths.key?(other::NAME)
      paths[other::NAME] = path if path
    end
  end

  def self.help
    "- #{help_name}: dates #{date_fields.join(', ')}. Filters #{filters_help}#{". Also groups by #{self::GROUPS.join(', ')}" if self::GROUPS.any?}"
  end

  def self.help_name
    self::NAME
  end

  # Column names, and the allowed values of the resource's own filters, so the model does not have to guess them. The
  # common filters and the column operators are the same for every resource, so get_data describes them once.
  def self.filters_help
    column_filters.keys.join(', ') + self::FILTERS.map do |name, property|
      allowed = property[:enum] || property.dig(:items, :enum)
      detail = allowed ? allowed.map { |value| value || 'null' }.join(' or ') : property[:description]
      detail ? ", #{name} (#{detail})" : ", #{name}"
    end.join
  end

  # Every filter, for the error that names the ones allowed.
  def self.all_filters_help
    "#{(COMMON_FILTERS.keys.map(&:to_s) + COLUMN_OPERATORS).join(', ')}, date_field (#{date_fields.join(' or ')}), #{filters_help}"
  end

  # A fact about the selection the agent must hear, such as a date range normalize chose because none was given.
  attr_reader :note

  def initialize(account:, user:)
    @account = account
    @user = user
  end

  def readable?
    true
  end

  # Everything get_data accepts for this resource, for when the short help is not enough, including the allowed values
  # of each filter and the keys the user's records use inside JSON columns.
  def describe
    columns = Captain::Copilot::Resources::Columns
    keys = columns.json(self.class::MODEL).index_with { |column| columns.json_keys(scope, column) }
    filters = self.class.filter_schema['properties'].except(*COMMON_FILTERS.keys.map(&:to_s), 'date_field', *COLUMN_OPERATORS)
    { resource: self.class::NAME, date_fields: self.class.date_fields, filters: filters, groups: self.class::GROUPS,
      can_start_from: self.class.sources.keys, linked_from: self.class.owners.keys, json_keys: keys }
  end

  # Resources that need more than the filters, such as the saved set a selection starts from, take it as a keyword.
  def normalize(filters, **)
    filters = filters.deep_stringify_keys
    errors = Captain::Copilot::SchemaErrors.messages(self.class.filter_schema, filters)
    raise ArgumentError, "Invalid #{self.class::NAME} filters: #{errors.join('; ')}. Allowed: #{self.class.all_filters_help}" if errors.any?
    raise ArgumentError, 'Pass newest or sample, not both' if filters['newest'] && filters['sample']

    filters = filters.reverse_merge('date_field' => self.class::DATE_FIELDS.first)
    unused = Captain::Copilot::Resources::Columns.unused(scope, filters)
    @note = "No #{self.class::NAME} record has a value for #{unused.join(', ')}. Pass describe for the fields records use." if unused.any?
    filters
  end

  # The visible records that match the filters, linked to the records of a source set when one is given, and not linked
  # to the records of an excluded set, such as inboxes without members. Saved sets are queries, so the whole chain is
  # one database query.
  def matching(filters, as_of:, source: nil, excluded: nil)
    relation = scope
    relation = relation.where(id: linked(source).select(:id)) if source
    relation = relation.where.not(id: linked(excluded).select(:id)) if excluded
    relation = Captain::Copilot::Resources::Columns.apply(apply_dates(relation, filters, as_of), filters, self.class.column_filters.keys.map(&:to_s))
    relation = Captain::Copilot::Resources::Links.apply(relation, self.class.owners, filters, account: @account, user: @user)
    filter(relation, filters).reorder(nil)
  end

  # Newest first by the date field, or oldest first, because reviews work through a selection in order. With newest,
  # that many records; otherwise up to one more than MAX_SELECTION, so the caller can tell when the selection was cut.
  def selected_ids(relation, filters, limit: nil)
    table = relation.klass.arel_table
    field = table[filters['date_field']]
    order = filters['oldest_first'] ? [field.asc.nulls_last, table[:id].asc] : [field.desc.nulls_last, table[:id].desc]
    relation.reorder(*order).limit(limit || filters['newest'] || (CopilotRun::MAX_SELECTION + 1)).pluck(:id)
  end

  # The first and last dates of the records, so the agent hears when the data starts after or ends before the period
  # asked about.
  def date_span(relation, field)
    column = relation.klass.arel_table[field]
    first, last = relation.pick(column.minimum, column.maximum)
    { date_field: field, first: first.iso8601, last: last.iso8601 } if first
  end

  # Names for the records a column points to, such as an inbox's name for inbox_id. Contact names follow the contacts
  # permission, as on the contacts page.
  def record_names(klass, ids)
    return {} if klass == Contact && !permitted?('contact_manage')

    klass.where(id: ids).to_h { |record| [record.id, "#{record.try(:name) || record.try(:title) || klass.model_name.human} (ID #{record.id})"] }
  end

  # A resource without filters of its own uses only the column filters.
  def filter(relation, _filters)
    relation
  end

  # A group that is not a column, as a hash of Captain::Copilot::Aggregation::Field attributes, or nil.
  def group_field(_name)
    nil
  end

  # Display rows for records the user can still see, in the order of ids.
  def rows(ids)
    found = scope.where(id: ids).includes(self.class::PRELOAD).index_by(&:id)
    ids.filter_map { |id| found[id] && row(found[id]) }
  end

  def date_range(filters, as_of)
    since = Time.iso8601(filters['since']) if filters['since']
    before = filters['before'] ? Time.iso8601(filters['before']) : as_of
    raise ArgumentError, 'since must be earlier than before' if since && since >= before
    raise ArgumentError, 'before cannot be in the future' if before > as_of

    [since, before]
  end

  private

  def linked(set)
    path = self.class.sources[set.resource]
    raise ArgumentError, "#{self.class::NAME} cannot start from #{set.resource}. Possible sources: #{self.class.sources.keys.join(', ')}" unless path

    path.call(Captain::Copilot::Resources.records(set))
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
