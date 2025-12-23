module Groupdate
  class SeriesBuilder
    attr_reader :period, :time_zone, :day_start, :week_start, :n_seconds, :options

    def initialize(period:, time_zone:, day_start:, week_start:, n_seconds:, **options)
      @period = period
      @time_zone = time_zone
      @week_start = week_start
      @day_start = day_start
      @n_seconds = n_seconds
      @options = options
      @week_start_key = Groupdate::Magic::DAYS[@week_start] if @week_start
    end

    def generate(data, default_value:, series_default: true, multiple_groups: false, group_index: nil)
      series = generate_series(data, multiple_groups, group_index)
      series = handle_multiple(data, series, multiple_groups, group_index)

      verified_data = {}
      series.each do |k|
        verified_data[k] = data.delete(k)
      end

      unless entire_series?(series_default)
        series = series.select { |k| verified_data[k] }
      end

      value = 0
      result = series.to_h do |k|
        value = verified_data[k] || (@options[:carry_forward] && value) || default_value
        key =
          if multiple_groups
            k[0...group_index] + [key_format.call(k[group_index])] + k[(group_index + 1)..-1]
          else
            key_format.call(k)
          end

        [key, value]
      end

      result
    end

    def round_time(time)
      if period == :custom
        return time_zone.at((time.to_time.to_i / n_seconds) * n_seconds)
      end

      time = time.to_time.in_time_zone(time_zone)

      if day_start != 0
        # apply day_start to a time object that's not affected by DST
        time = time.change(zone: utc)
        time -= day_start.seconds
      end

      time =
        case period
        when :second
          time.change(usec: 0)
        when :minute
          time.change(sec: 0)
        when :hour
          time.change(min: 0)
        when :day
          time.beginning_of_day
        when :week
          time.beginning_of_week(@week_start_key)
        when :month
          time.beginning_of_month
        when :quarter
          time.beginning_of_quarter
        when :year
          time.beginning_of_year
        when :hour_of_day
          time.hour
        when :minute_of_hour
          time.min
        when :day_of_week
          time.days_to_week_start(@week_start_key)
        when :day_of_month
          time.day
        when :month_of_year
          time.month
        when :day_of_year
          time.yday
        else
          raise Groupdate::Error, "Invalid period"
        end

      if day_start != 0 && time.is_a?(Time)
        time += day_start.seconds
        time = time.change(zone: time_zone)
      end

      time
    end

    def time_range
      @time_range ||= begin
        time_range = options[:range]

        if time_range.is_a?(Range)
          # check types
          [time_range.begin, time_range.end].each do |v|
            case v
            when nil, Date, Time
              # good
            else
              raise ArgumentError, "Range bounds should be Date or Time, not #{v.class.name}"
            end
          end

          start = time_range.begin
          start = start.in_time_zone(time_zone) if start

          exclude_end = time_range.exclude_end?

          finish = time_range.end
          finish = finish.in_time_zone(time_zone) if finish
          if time_range.end.is_a?(Date) && !time_range.end.is_a?(DateTime) && !exclude_end
            finish += 1.day
            exclude_end = true
          end

          if options[:expand_range]
            start = round_time(start) if start
            if finish && !(finish == round_time(finish) && exclude_end)
              finish = round_time(finish) + step
              exclude_end = true
            end
          end

          time_range = Range.new(start, finish, exclude_end)
        elsif !time_range && options[:last]
          step = step()
          raise ArgumentError, "Cannot use last option with #{period}" unless step

          # loop instead of multiply to change start_at - see #151
          start_at = now
          (options[:last].to_i - 1).times do
            start_at -= step
          end

          time_range =
            if options[:current] == false
              round_time(start_at - step)...round_time(now)
            else
              # extend to end of current period
              round_time(start_at)...(round_time(now) + step)
            end
        end
        time_range
      end
    end

    private

    def now
      @now ||= time_zone.now
    end

    def generate_series(data, multiple_groups, group_index)
      case period
      when :day_of_week
        0..6
      when :hour_of_day
        0..23
      when :minute_of_hour
        0..59
      when :day_of_month
        1..31
      when :day_of_year
        1..366
      when :month_of_year
        1..12
      else
        time_range = self.time_range
        time_range =
          if time_range.is_a?(Range) && time_range.begin && time_range.end
            time_range
          else
            # use first and last values
            sorted_keys =
              if multiple_groups
                data.keys.map { |k| k[group_index] }.sort
              else
                data.keys.sort
              end

            if time_range.is_a?(Range)
              if sorted_keys.any?
                if time_range.begin
                  time_range.begin..sorted_keys.last
                else
                  Range.new(sorted_keys.first, time_range.end, time_range.exclude_end?)
                end
              else
                nil..nil
              end
            else
              tr = sorted_keys.first..sorted_keys.last
              if options[:current] == false && sorted_keys.any? && round_time(now) >= tr.last
                tr = tr.first...round_time(now)
              end
              tr
            end
          end

        if time_range.begin
          series = [round_time(time_range.begin)]

          step = step()

          last_step = series.last
          day_start_hour = day_start / 3600
          loop do
            next_step = last_step + step
            next_step = round_time(next_step) if next_step.hour != day_start_hour # add condition to speed up
            break unless time_range.cover?(next_step)

            if next_step == last_step
              last_step += step
              next
            end
            series << next_step
            last_step = next_step
          end

          series
        else
          []
        end
      end
    end

    def key_format
      @key_format ||= begin
        locale = options[:locale] || I18n.locale

        if options[:format]
          if options[:format].respond_to?(:call)
            options[:format]
          else
            sunday = time_zone.parse("2014-03-02 00:00:00")
            lambda do |key|
              case period
              when :hour_of_day
                key = sunday + key.hours + day_start.seconds
              when :minute_of_hour
                key = sunday + key.minutes + day_start.seconds
              when :day_of_week
                key = sunday + key.days + (week_start + 1).days
              when :day_of_month
                key = Date.new(2014, 1, key).to_time
              when :month_of_year
                key = Date.new(2014, key, 1).to_time
              end
              I18n.localize(key, format: options[:format], locale: locale)
            end
          end
        elsif [:day, :week, :month, :quarter, :year].include?(period)
          lambda { |k| k.to_date }
        else
          lambda { |k| k }
        end
      end
    end

    def step
      if period == :quarter
        3.months
      elsif period == :custom
        n_seconds
      elsif 1.respond_to?(period)
        1.send(period)
      end
    end

    def handle_multiple(data, series, multiple_groups, group_index)
      reverse = options[:reverse]

      if multiple_groups
        keys = data.keys.map { |k| k[0...group_index] + k[(group_index + 1)..-1] }.uniq
        series = series.to_a.reverse if reverse
        keys.flat_map do |k|
          series.map { |s| k[0...group_index] + [s] + k[group_index..-1] }
        end
      elsif reverse
        series.to_a.reverse
      else
        series
      end
    end

    def entire_series?(series_default)
      options.key?(:series) ? options[:series] : series_default
    end

    def utc
      @utc ||= ActiveSupport::TimeZone["Etc/UTC"]
    end
  end
end
