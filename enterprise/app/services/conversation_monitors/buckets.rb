class ConversationMonitors::Buckets
  INTERVAL_HOURS = { 'hour' => 1, 'six_hours' => 6, 'day' => 24 }.freeze
  MAX_BUCKETS = 744
  attr_reader :since, :until_time, :interval, :timezone

  def initialize(params, default_timezone: 'UTC')
    @since = Time.at(self.class.integer!(params[:since])).utc
    @until_time = Time.at(self.class.integer!(params[:until])).utc
    @interval = params[:interval]
    @timezone = params[:timezone] || default_timezone
    validate!
  end

  def self.integer!(value)
    return value if value.is_a?(Integer) && value.between?(0, 999_999_999_999)
    return value.to_i if value.is_a?(String) && value.match?(/\A\d{1,12}\z/)

    raise CustomExceptions::MonitorParametersError, 'invalid_parameters'
  end

  def ranges
    @ranges ||= build_ranges
  end

  def range_at(timestamp)
    ranges.find { |range| range.begin.to_i == self.class.integer!(timestamp) } ||
      raise(CustomExceptions::MonitorParametersError, 'invalid_bucket')
  end

  private

  def build_ranges
    result = boundaries.each_cons(2).filter_map do |first, last|
      next if first >= until_time || last <= since

      [first, since].max...[last, until_time].min
    end
    raise CustomExceptions::MonitorParametersError, 'too_many_buckets' if result.size > MAX_BUCKETS

    result
  end

  def validate!
    valid = INTERVAL_HOURS.key?(interval) && timezone.is_a?(String) && TZInfo::Timezone.all_identifiers.include?(timezone) &&
            since < until_time && until_time - since <= 366.days
    raise CustomExceptions::MonitorParametersError, 'invalid_parameters' unless valid

    @zone = ActiveSupport::TimeZone[timezone]
  end

  def boundaries
    first_date = since.in_time_zone(@zone).to_date - 1
    last_date = until_time.in_time_zone(@zone).to_date + 1
    (first_date..last_date).flat_map do |date|
      (0...24).step(INTERVAL_HOURS.fetch(interval)).flat_map { |hour| wall_clock_boundaries(date, hour) }
    end.uniq.sort
  end

  def wall_clock_boundaries(date, hour)
    local = Time.utc(date.year, date.month, date.day, hour)
    periods = @zone.tzinfo.periods_for_local(local)
    return [@zone.local(date.year, date.month, date.day, hour).utc] if periods.empty?

    periods.map { |period| local - period.utc_total_offset }
  end
end
