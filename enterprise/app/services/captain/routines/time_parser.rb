class Captain::Routines::TimeParser
  def initialize(reference_time:, timezone:)
    @reference_time = reference_time
    @timezone = timezone
  end

  def duration!(value)
    duration = Fugit.parse_duration(value.to_s)
    raise ArgumentError, "Invalid duration '#{value}'" unless duration

    duration.to_sec.seconds
  end

  def range!(value)
    return explicit_range!(value) if value.is_a?(Hash)

    named_or_relative_range(value) || date_range(value)
  rescue Date::Error
    raise ArgumentError, "Invalid relative date or range '#{value}'"
  end

  def timestamp!(value)
    duration = Fugit.parse_duration(value.to_s)
    return reference_time + duration.to_sec.seconds if duration
    return local_time.tomorrow.beginning_of_day if value.to_s.casecmp('tomorrow').zero?

    Time.zone.parse(value.to_s) || raise(ArgumentError, "Invalid timestamp '#{value}'")
  end

  private

  attr_reader :reference_time, :timezone

  def named_or_relative_range(value)
    case value.to_s.downcase.strip
    when 'today'
      local_time.all_day
    when 'yesterday'
      (local_time - 1.day).all_day
    when /\A(?:last|previous)\s+(\d+)\s*(minutes?|hours?|days?|weeks?|months?)\z/
      amount = Regexp.last_match(1).to_i.public_send(Regexp.last_match(2).singularize)
      (reference_time - amount)..reference_time
    end
  end

  def date_range(value)
    date = Date.iso8601(value.to_s)
    ActiveSupport::TimeZone[timezone].local(date.year, date.month, date.day).all_day
  end

  def explicit_range!(value)
    from = Time.zone.parse(value['from'] || value[:from])
    to = Time.zone.parse(value['to'] || value[:to])
    raise ArgumentError, "Invalid time range '#{value}'" unless from && to

    from..to
  end

  def local_time
    reference_time.in_time_zone(timezone)
  end
end
