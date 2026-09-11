module Filters::DateFilterHelper
  def date_filter(current_filter, query_hash, filter_operator_value)
    column = "#{filter_config[:table_name]}.#{query_hash[:attribute_key]}"
    if query_hash.key?('timezone')
      timezone = filter_timezone(query_hash).tzinfo.identifier
      column = ActiveRecord::Base.sanitize_sql_array(["(#{column} AT TIME ZONE 'UTC' AT TIME ZONE ?)", timezone])
    end
    "(#{column})::#{current_filter['data_type']} #{filter_operator_value} #{query_hash[:query_operator]}"
  end

  def filter_timezone(query_hash)
    return Time.zone unless query_hash.key?('timezone')

    timezone = query_hash['timezone']
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'timezone') unless timezone.is_a?(String)

    Time.find_zone!(TZInfo::Timezone.get(timezone))
  rescue TZInfo::InvalidTimezoneIdentifier
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: 'timezone')
  end
end
