require 'active_support/all'
require 'working_hours/config'

module WorkingHours
  module Computation

    def add_days origin, days, config: nil
      return origin if days.zero?

      config ||= wh_config
      time = in_config_zone(origin, config: config)
      time += (days <=> 0).day until working_day?(time, config: config)

      while days > 0
        time += 1.day
        days -= 1 if working_day?(time, config: config)
      end
      while days < 0
        time -= 1.day
        days += 1 if working_day?(time, config: config)
      end
      convert_to_original_format time, origin
    end

    def add_hours origin, hours, config: nil
      config ||= wh_config
      add_minutes origin, hours * 60, config: config
    end

    def add_minutes origin, minutes, config: nil
      config ||= wh_config
      add_seconds origin, minutes * 60, config: config
    end

    def add_seconds origin, seconds, config: nil
      config ||= wh_config
      time = in_config_zone(origin, config: config)
      while seconds > 0
        # roll to next business period
        time = advance_to_working_time(time, config: config)
        # look at working ranges
        time_in_day = time.seconds_since_midnight
        working_hours_for(time, config: config).each do |from, to|
          if time_in_day >= from and time_in_day < to
            # take all we can
            take = [to - time_in_day, seconds].min
            # advance time
            time += take
            # decrease seconds
            seconds -= take
          end
        end
      end
      while seconds < 0
        # roll to previous business period
        time = return_to_exact_working_time(time, config: config)
        # look at working ranges
        time_in_day = time.seconds_since_midnight
        
        working_hours_for(time, config: config).reverse_each do |from, to|
          if time_in_day > from and time_in_day <= to
            # take all we can
            take = [time_in_day - from, -seconds].min
            # advance time
            time -= take
            # decrease seconds
            seconds += take
          end
        end
      end
      convert_to_original_format(time.round, origin)
    end

    def advance_to_working_time time, config: nil
      config ||= wh_config
      time = in_config_zone(time, config: config)
      loop do
        # skip holidays and weekends
        while not working_day?(time, config: config)
          time = (time + 1.day).beginning_of_day
        end
        # find first working range after time
        time_in_day = time.seconds_since_midnight
        
        working_hours_for(time, config: config).each do |from, to|
          return time if time_in_day >= from and time_in_day < to
          return move_time_of_day(time, from) if from >= time_in_day
        end
        # if none is found, go to next day and loop
        time = (time + 1.day).beginning_of_day
      end
    end

    def advance_to_closing_time time, config: nil
      config ||= wh_config
      time = in_config_zone(time, config: config)
      loop do
        # skip holidays and weekends
        while not working_day?(time, config: config)
          time = (time + 1.day).beginning_of_day
        end
        # find next working range after time
        time_in_day = time.seconds_since_midnight
        working_hours_for(time, config: config).each do |from, to|
          return move_time_of_day(time, to) if time_in_day < to
        end
        # if none is found, go to next day and loop
        time = (time + 1.day).beginning_of_day
      end
    end

    def next_working_time(time, config: nil)
      time = advance_to_closing_time(time, config: config) if in_working_hours?(time, config: config)
      advance_to_working_time(time, config: config)
    end

    def return_to_working_time(time, config: nil)
      # return_to_exact_working_time may return values with a high number of milliseconds,
      # this is necessary for the end of day hack, here we return a rounded value for the
      # public API
      return_to_exact_working_time(time, config: config).round
    end

    def return_to_exact_working_time time, config: nil
      config ||= wh_config
      time = in_config_zone(time, config: config)
      loop do
        # skip holidays and weekends
        while not working_day?(time, config: config)
          time = (time - 1.day).end_of_day
        end
        # find last working range before time
        time_in_day = time.seconds_since_midnight
        working_hours_for(time, config: config).reverse_each do |from, to|
          return time if time_in_day > from and time_in_day <= to
          return move_time_of_day(time, to) if to <= time_in_day
        end
        # if none is found, go to previous day and loop
        time = (time - 1.day).end_of_day
      end
    end

    def working_day? time, config: nil
      config ||= wh_config
      time = in_config_zone(time, config: config)

      (config[:working_hours][time.wday].present? && !config[:holidays].include?(time.to_date)) ||
        config[:holiday_hours].include?(time.to_date)
    end

    def in_working_hours? time, config: nil
      config ||= wh_config
      time = in_config_zone(time, config: config)
      return false if not working_day?(time, config: config)
      time_in_day = time.seconds_since_midnight
      working_hours_for(time, config: config).each do |from, to|
        return true if time_in_day >= from and time_in_day < to
      end
      false
    end

    def working_days_between from, to, config: nil
      config ||= wh_config
      if to < from
        -working_days_between(to, from, config: config)
      else
        from = in_config_zone(from, config: config)
        to = in_config_zone(to, config: config)
        days = 0
        while from.to_date < to.to_date
          from += 1.day
          days += 1 if working_day?(from, config: config)
        end
        days
      end
    end

    def working_time_between from, to, config: nil
      config ||= wh_config
      if to < from
        -working_time_between(to, from, config: config)
      else
        from = advance_to_working_time(in_config_zone(from, config: config))
        to = in_config_zone(to, config: config)
        distance = 0
        while from < to
          from_was = from
          # look at working ranges
          time_in_day = from.seconds_since_midnight
          working_hours_for(from, config: config).each do |begins, ends|
            if time_in_day >= begins and time_in_day < ends
              if (to - from) > (ends - time_in_day)
                # take all the range and continue
                distance += (ends - time_in_day)
                from = move_time_of_day(from, ends)
              else
                # take only what's needed and stop
                distance += (to - from)
                from = to
              end
            end
          end
          # roll to next business period
          from = advance_to_working_time(from, config: config)
          raise "Invalid loop detected in working_time_between (from=#{from.iso8601(12)}, to=#{to.iso8601(12)}, distance=#{distance}, config=#{config}), please open an issue ;)" unless from > from_was
        end
        distance.round # round up to supress miliseconds introduced by 24:00 hack
      end
    end

    private

    # Changes the time of the day to match given time (in seconds since midnight)
    # preserving nanosecond prevision (rational number) and honoring time shifts
    #
    # This replaces the previous implementation which was:
    #   time.beginning_of_day + seconds
    # (because this one would shift hours during time shifts days)
    def move_time_of_day time, seconds
      # return time.beginning_of_day + seconds
      hour = (seconds / 3600).to_i
      seconds %= 3600
      minutes = (seconds / 60).to_i
      seconds %= 60
      # sec/usec separation is required for ActiveSupport <= 5.1
      usec = ((seconds % 1) * 10**6)
      time.change(hour: hour, min: minutes, sec: seconds.to_i, usec: usec)
    end

    def wh_config
      WorkingHours::Config.precompiled
    end

    # fix for ActiveRecord < 4, doesn't implement in_time_zone for Date
    def in_config_zone time, config: nil
      if time.respond_to? :in_time_zone
        time.in_time_zone(config[:time_zone])
      elsif time.is_a? Date
        config[:time_zone].local(time.year, time.month, time.day)
      else
        raise TypeError.new("Can't convert #{time.class} to a Time")
      end
    end

    def convert_to_original_format time, original
      case original
      when Date then time.to_date
      when DateTime then time.to_datetime
      else time
      end
    end

    def working_hours_for(time, config:)
      config[:holiday_hours][time.to_date] || config[:working_hours][time.wday]
    end
  end
end
