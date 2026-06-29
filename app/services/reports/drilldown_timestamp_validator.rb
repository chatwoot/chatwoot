module Reports::DrilldownTimestampValidator
  TIMESTAMP_PARAMS = %i[bucket_timestamp since until].freeze

  module_function

  def valid?(params)
    timestamps = TIMESTAMP_PARAMS.index_with { |param| integer_param(params[param]) }
    return false if timestamps.values.any?(&:nil?)

    timestamps[:since] < timestamps[:until] &&
      timestamps[:bucket_timestamp] >= timestamps[:since] &&
      timestamps[:bucket_timestamp] < timestamps[:until]
  end

  def integer_param(value)
    return unless value.to_s.match?(/\A\d+\z/)

    value.to_i
  end
end
