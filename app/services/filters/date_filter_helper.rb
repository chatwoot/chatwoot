module Filters::DateFilterHelper
  TIMESTAMP_ATTRIBUTES = %w[created_at last_activity_at].freeze

  def date_filter(current_filter, query_hash, filter_operator_value)
    column = "#{filter_config[:table_name]}.#{query_hash[:attribute_key]}"
    return "#{column} #{filter_operator_value} #{query_hash[:query_operator]}" if timezone_aware_timestamp_filter?(query_hash)

    "(#{column})::#{current_filter['data_type']} #{filter_operator_value} #{query_hash[:query_operator]}"
  end

  def timezone_aware_timestamp_filter?(query_hash)
    query_hash.key?('timezone') && TIMESTAMP_ATTRIBUTES.include?(query_hash['attribute_key'])
  end

  def self.timezone(identifier)
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'timezone') unless identifier.is_a?(String)

    ActiveSupport::TimeZone[TZInfo::Timezone.get(identifier)]
  rescue TZInfo::InvalidTimezoneIdentifier
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'timezone')
  end

  def filter_timezone(query_hash)
    Filters::DateFilterHelper.timezone(query_hash['timezone'])
  end

  def timestamp_filter_boundary(date, query_hash)
    boundary_date = query_hash['filter_operator'] == 'is_greater_than' ? date.tomorrow : date
    filter_timezone(query_hash).local(boundary_date.year, boundary_date.month, boundary_date.day).utc
  end

  def timezone_aware_filter_operation(query_hash, current_index, filter_value)
    return unless timezone_aware_timestamp_filter?(query_hash)

    @filter_values["value_#{current_index}"] = timestamp_filter_boundary(filter_value, query_hash)
    operator = query_hash['filter_operator'] == 'is_less_than' ? '<' : '>='
    "#{operator} :value_#{current_index}"
  end

  def days_before_filter_query(query_hash, current_index)
    days = Integer(query_hash['values'][0].to_s, 10, exception: false)
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash['attribute_key']) unless days&.between?(1, 998)

    timezone = query_hash.key?('timezone') ? filter_timezone(query_hash) : Time.zone
    date = timezone.today - days.days
    updated_query_hash = query_hash.to_h.with_indifferent_access.merge(
      values: [date.strftime],
      filter_operator: 'is_less_than'
    )

    lt_gt_filter_query(updated_query_hash, current_index)
  end
end
