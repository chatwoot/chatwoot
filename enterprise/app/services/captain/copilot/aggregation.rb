# Measures a selection in the database, so the model never tallies rows. get_data's group_by and aggregate both use it.
#
# A field is one of:
#   day, week, month or year   a period of the selection's date field
#   column:part                a part of a date column, such as created_at:hour_of_day
#   a column                   or the name of its association, such as inbox for inbox_id; linked records are named
#   column.key                 a key inside a JSON column, such as additional_attributes.country
#   label                      for records with labels; a record counts once for each of its labels
#   a name the resource adds   such as sender for messages (BaseResource#group_field)
class Captain::Copilot::Aggregation
  MEASURES = %w[count sum average median minimum maximum].freeze
  PERIODS = %w[day week month year].freeze
  DATE_PARTS = {
    'hour_of_day' => ->(hour) { format('%02d:00', hour) }, 'day_of_week' => ->(day) { Date::DAYNAMES[day] },
    'day' => ->(date) { date.to_date.iso8601 }, 'week' => ->(date) { "week of #{date.to_date.iso8601}" },
    'month' => ->(date) { date.strftime('%Y-%m') }, 'year' => ->(date) { date.strftime('%Y') }
  }.freeze
  # Groupdate takes a week start only for the parts that depend on it.
  WEEK_PARTS = %w[week day_of_week].freeze
  AGGREGATES = { 'count' => Arel::Nodes::Count, 'sum' => Arel::Nodes::Sum, 'average' => Arel::Nodes::Avg,
                 'minimum' => Arel::Nodes::Min, 'maximum' => Arel::Nodes::Max }.freeze
  # Enough for every weekday and hour pair.
  MAX_GROUPS = 200

  # A date field has a column and a part instead of an expression. names is the model the values are IDs of, and join
  # is set when the labels must be joined.
  Field = Struct.new(:expression, :column, :part, :names, :join, keyword_init: true) do
    def date?
      part.present?
    end

    def selected
      expression || column
    end
  end

  # range is since to before on date_field, so periods without records inside it are listed with nothing.
  def initialize(resource, relation, time_zone:, date_field:, range: nil)
    @resource = resource
    @model = resource.class::MODEL
    @relation = relation
    @time_zone = time_zone
    @date_field = date_field
    @range = range
    columns = Captain::Copilot::Resources::Columns
    @readable = columns.names(@model)
    @dates = columns.names(@model, columns::DATE_TYPES)
    @numbers = columns.numbers(@model)
  end

  def call(measure:, column: nil, duration: nil, group_by: [])
    raise ArgumentError, "measure must be one of: #{MEASURES.join(', ')}" unless MEASURES.include?(measure)

    fields = Array(group_by).map { |field| parse_field(field) }
    raise ArgumentError, 'group_by takes at most two fields' if fields.size > 2

    value = value_expression(measure, column, duration)
    results = measure == 'median' ? medians(fields, value) : calculate(fields, measure, value)
    { measure: measure, of: of(column, duration), unit: duration ? 'hours' : nil, **formatted(results, fields, duration, measure),
      without_date: without_date(fields, measure) }.compact
  end

  private

  def parse_field(field)
    name, part = field.split(':', 2)
    return date_field(field, column_for(name), part) if part

    named_field(name) || column_field(field, column_for(name))
  end

  def named_field(name)
    return Field.new(column: @date_field, part: name) if PERIODS.include?(name)
    return Field.new(expression: ActsAsTaggableOn::Tag.arel_table[:name], join: true) if name == 'label' && @model.reflect_on_association(:labels)
    return Field.new(expression: @resource.json_group_field(name, @relation)) if name.include?('.')

    custom = @resource.group_field(name)
    Field.new(**custom) if custom
  end

  def column_field(field, column)
    raise ArgumentError, "Unknown field #{field}. Columns: #{@readable.join(', ')}" unless @readable.include?(column)
    raise ArgumentError, "#{field} is a date column; group it by a part, written #{field}:part" if @dates.include?(column)

    link = @model.reflect_on_all_associations(:belongs_to).find { |candidate| !candidate.polymorphic? && candidate.foreign_key.to_s == column }
    Field.new(expression: @model.arel_table[column], names: link&.klass)
  end

  def date_field(field, column, part)
    unless @dates.include?(column) && DATE_PARTS.key?(part)
      raise ArgumentError, "#{field}: only a date column takes a part, which is one of #{DATE_PARTS.keys.join(', ')}"
    end

    Field.new(column: column, part: part)
  end

  def column_for(name)
    link = @model.reflect_on_association(name.to_sym)
    link&.belongs_to? && !link.polymorphic? ? link.foreign_key.to_s : name
  end

  def value_expression(measure, column, duration)
    return if measure == 'count'
    raise ArgumentError, "#{measure} needs a numeric column or a duration" if column.nil? == duration.nil?
    return duration_expression(duration) if duration
    raise ArgumentError, "#{column} is not a numeric column. Numeric columns: #{@numbers.join(', ')}" unless @numbers.include?(column)

    @model.arel_table[column]
  end

  # The seconds from the first date column to the second.
  def duration_expression(duration)
    from, to = duration
    raise ArgumentError, "duration takes two date columns: #{@dates.join(', ')}" unless duration.size == 2 && (duration - @dates).empty?

    table = @model.arel_table
    Arel::Nodes::Extract.new(table[to] - table[from], :epoch)
  end

  def calculate(fields, measure, value)
    relation = ranked(grouped(fields), fields, measure, value)
    measure == 'count' ? relation.count : relation.public_send(measure, value)
  end

  # Periods are cut in the account's reporting time zone and weeks start on Sunday, as on the reports pages. Groupdate
  # also filters the grouped column by range, so periods of another date column do not take it.
  def grouped(fields)
    fields.reduce(joined(fields)) do |scope, field|
      next scope.group(field.expression) unless field.date?

      options = { time_zone: @time_zone, series: fields.one?, range: (@range if fields.one? && field.column == @date_field) }
      options[:week_start] = :sunday if WEEK_PARTS.include?(field.part)
      scope.group_by_period(field.part.to_sym, field.column, **options)
    end
  end

  # With one field, the group with no value comes first and takes one more row, so the limit never drops it.
  def ranked(relation, fields, measure, value)
    return relation if fields.empty? || fields.any?(&:date?)

    largest = AGGREGATES.fetch(measure).new([value || Arel.star]).desc.nulls_last
    return relation.order(largest).limit(MAX_GROUPS + 1) unless fields.one?

    relation.order(fields.first.expression.eq(nil).desc, largest).limit(MAX_GROUPS + 2)
  end

  def joined(fields)
    fields.any?(&:join) ? @relation.left_joins(:labels) : @relation
  end

  def medians(fields, value)
    Captain::Copilot::Aggregation::Medians.new(joined(fields), time_zone: @time_zone).call(fields, value)
  end

  # One field reports its group with no value as without_value, taken out before the largest groups are cut.
  def formatted(results, fields, duration, measure)
    return { value: display_value(results, duration) } if fields.empty?

    check_periods(results, fields)
    without = results.delete(nil) if fields.one?
    rows = labeled(results.first(MAX_GROUPS).to_h, fields).map do |labels, value|
      { group: fields.one? ? labels.first : labels, value: display_value(value, duration) }
    end
    cut = "Showing the #{MAX_GROUPS} largest of #{group_count(results, fields, measure)} groups." if results.size > MAX_GROUPS
    { groups: rows, without_value: display_value(without, duration), cut: cut }
  end

  # The query keeps only the largest groups, so the number of groups is counted apart. It is the number of distinct
  # values, such as the conversations a set of messages belongs to. Medians already hold every group.
  def group_count(results, fields, measure)
    return results.size if measure == 'median'

    expressions = fields.map(&:expression)
    groups = joined(fields).unscope(:select, :order)
    groups = groups.where(expressions.first.not_eq(nil)) if fields.one?
    @model.unscoped.from(groups.group(expressions).select(expressions).arel.as('groups')).count
  end

  def check_periods(results, fields)
    return unless results.size > MAX_GROUPS && fields.any?(&:date?)

    raise ArgumentError, "These fields give #{results.size} periods. Use a larger period or narrower filters."
  end

  def labeled(results, fields)
    keys = results.keys.map { |key| fields.one? ? [key] : key }
    names = fields.each_with_index.map { |field, index| record_names(field, keys.map { |key| key[index] }) }
    keys.zip(results.values).map do |key, value|
      [key.each_with_index.map { |part, index| label(part, fields[index], names[index]) }, value]
    end
  end

  def record_names(field, ids)
    field.names ? @resource.record_names(field.names, ids.compact.uniq) : {}
  end

  # Only two fields reach here with a missing value; one field reports it as without_value.
  def label(value, field, names)
    return 'None' if value.nil?
    return DATE_PARTS.fetch(field.part).call(value) if field.date?

    names.fetch(value) { value.to_s }
  end

  # Periods leave out the records with no date, so a count by period says how many those are.
  def without_date(fields, measure)
    return unless measure == 'count' && fields.one? && fields.first.date?

    count = @relation.where(fields.first.column => nil).count
    count if count.positive?
  end

  def display_value(value, duration)
    return if value.nil?
    return (value.to_f / 3600).round(1) if duration

    value.is_a?(Integer) ? value : value.to_f.round(2)
  end

  def of(column, duration)
    duration ? "time from #{duration.first} to #{duration.second}" : column
  end
end
