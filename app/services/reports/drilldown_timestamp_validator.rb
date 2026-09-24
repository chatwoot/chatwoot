module Reports::DrilldownTimestampValidator
  extend TimezoneHelper

  TIMESTAMP_PARAMS = %i[bucket_timestamp since until].freeze
  DEFAULT_GROUP_BY = V2::Reports::DrilldownBuilder::DEFAULT_GROUP_BY
  SUPPORTED_GROUP_BY = V2::Reports::DrilldownBuilder::SUPPORTED_GROUP_BY

  module_function

  def valid?(params)
    timestamps = TIMESTAMP_PARAMS.index_with { |param| integer_param(params[param]) }
    return false if timestamps.values.any?(&:nil?)
    return false unless timestamps[:since] < timestamps[:until]

    bucket_overlaps_requested_range?(params, timestamps)
  end

  def integer_param(value)
    return unless value.to_s.match?(/\A\d+\z/)

    value.to_i
  end

  def bucket_overlaps_requested_range?(params, timestamps)
    bucket_start = Time.zone.at(timestamps[:bucket_timestamp]).in_time_zone(timezone(params))
    bucket_end = bucket_end_for(bucket_start, group_by(params))
    requested_start = Time.zone.at(timestamps[:since])
    requested_end = Time.zone.at(timestamps[:until])

    bucket_start < requested_end && bucket_end > requested_start
  rescue ArgumentError, RangeError
    false
  end

  def bucket_end_for(bucket_start, group_by)
    {
      'hour' => bucket_start + 1.hour,
      'day' => bucket_start + 1.day,
      'week' => bucket_start + 1.week,
      'month' => bucket_start + 1.month,
      'year' => bucket_start + 1.year
    }.fetch(group_by)
  end

  def group_by(params)
    group = params[:group_by].to_s
    SUPPORTED_GROUP_BY.include?(group) ? group : DEFAULT_GROUP_BY
  end

  def timezone(params)
    timezone_name_from_offset(params[:timezone_offset])
  end
end
