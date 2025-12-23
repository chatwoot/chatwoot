require 'set'

module WorkingHours
  class InvalidConfiguration < StandardError
    attr_reader :data, :error_code

    def initialize(error_code, data: nil)
      @data = data
      @error_code = error_code
      super compose_message(error_code)
    end

    def compose_message(error_code)
      case error_code
      when :empty then "No working hours given"
      when :empty_day then "No working hours given for day `#{@data[:day]}`"
      when :holidays_not_array then "Invalid type for holidays: #{@data[:holidays_class]} - must act like an array"
      when :holiday_not_date then "Invalid holiday: #{@data[:day]} - must be Date"
      when :invalid_day_keys then "Invalid day identifier(s): #{@data[:invalid_keys]} - must be 3 letter symbols"
      when :invalid_format then "Invalid time: #{@data[:time]} - must be 'HH:MM(:SS)'"
      when :invalid_holiday_keys then "Invalid day identifier(s): #{@data[:invalid_keys]} - must be a Date object"
      when :invalid_timezone then "Invalid time zone: #{@data[:zone]} - must be String or ActiveSupport::TimeZone"
      when :invalid_type then "Invalid type for `#{@data[:day]}`: #{@data[:hours_class]} - must be Hash"
      when :outside_of_day then "Invalid time: #{@data[:time]} - outside of day"
      when :overlap then "Invalid range: #{@data[:start]} => #{@data[:finish]} - overlaps previous range"
      when :unknown_timezone then "Unknown time zone: #{@data[:zone]}"
      when :wrong_order then "Invalid range: #{@data[:start]} => #{@data[:finish]} - ends before it starts"
      else "Invalid Configuration"
      end
    end
  end


  class Config
    TIME_FORMAT = /\A([0-2][0-9])\:([0-5][0-9])(?:\:([0-5][0-9]))?\z/
    DAYS_OF_WEEK = [:sun, :mon, :tue, :wed, :thu, :fri, :sat]
    MIDNIGHT = Rational('86399.999999')

    class << self
      def working_hours
        config[:working_hours]
      end

      def working_hours=(val)
        validate_working_hours! val
        config[:working_hours] = val
        global_config[:working_hours] = val
        config.delete :precompiled
      end

      def holidays
        config[:holidays]
      end

      def holidays=(val)
        validate_holidays! val
        config[:holidays] = val
        global_config[:holidays] = val
        config.delete :precompiled
      end

      def holiday_hours
        config[:holiday_hours]
      end

      def holiday_hours=(val)
        validate_holiday_hours! val
        config[:holiday_hours] = val
        global_config[:holiday_hours] = val
        config.delete :precompiled
      end

      # Returns an optimized for computing version
      def precompiled
        config_hash = [
          config[:working_hours],
          config[:holiday_hours],
          config[:holidays],
          config[:time_zone]
        ].hash

        if config_hash != config[:config_hash]
          config[:config_hash] = config_hash
          config.delete :precompiled
        end

        config[:precompiled] ||= begin
          validate_working_hours! config[:working_hours]
          validate_holiday_hours! config[:holiday_hours]
          validate_holidays! config[:holidays]
          validate_time_zone! config[:time_zone]
          compiled = { working_hours: Array.new(7) { Hash.new }, holiday_hours: {} }
          working_hours.each do |day, hours|
            hours.each do |start, finish|
              compiled[:working_hours][DAYS_OF_WEEK.index(day)][compile_time(start)] = compile_time(finish)
            end
          end
          holiday_hours.each do |day, hours|
            compiled[:holiday_hours][day] = {}
            hours.each do |start, finish|
              compiled[:holiday_hours][day][compile_time(start)] = compile_time(finish)
            end
          end
          compiled[:holidays] = Set.new(holidays)
          compiled[:time_zone] = time_zone
          compiled
        end
      end

      def time_zone
        config[:time_zone]
      end

      def time_zone=(val)
        zone = validate_time_zone! val
        config[:time_zone] = zone
        global_config[:time_zone] = val
        config.delete :precompiled
      end

      def reset!
        Thread.current[:working_hours] = default_config
      end

      def with_config(working_hours: nil, holiday_hours: nil, holidays: nil, time_zone: nil)
        original_working_hours = self.working_hours
        original_holiday_hours = self.holiday_hours
        original_holidays = self.holidays
        original_time_zone = self.time_zone
        self.working_hours = working_hours if working_hours
        self.holiday_hours = holiday_hours if holiday_hours
        self.holidays = holidays if holidays
        self.time_zone = time_zone if time_zone
        yield
      ensure
        self.working_hours = original_working_hours
        self.holiday_hours = original_holiday_hours
        self.holidays = original_holidays
        self.time_zone = original_time_zone
      end

      private

      def config
        Thread.current[:working_hours] ||= global_config.dup
      end

      def global_config
        @@global_config ||= default_config
      end

      def default_config
        {
          working_hours: {
            mon: {'09:00' => '17:00'},
            tue: {'09:00' => '17:00'},
            wed: {'09:00' => '17:00'},
            thu: {'09:00' => '17:00'},
            fri: {'09:00' => '17:00'}
          },
          holiday_hours: {},
          holidays: [],
          time_zone: ActiveSupport::TimeZone['UTC']
        }
      end

      def compile_time time
        hour = time[TIME_FORMAT,1].to_i
        min = time[TIME_FORMAT,2].to_i
        sec = time[TIME_FORMAT,3].to_i
        time = hour * 3600 + min * 60 + sec
        # Converts 24:00 to 23:59:59.999999
        return MIDNIGHT if time == 86400
        time
      end

      def validate_hours! dates
        dates.each do |day, hours|
          if not hours.is_a? Hash
            raise InvalidConfiguration.new :invalid_type, data: { day: day, hours_class: hours.class }
          elsif hours.empty?
            raise InvalidConfiguration.new :empty_day, data: { day: day }
          end
          last_time = nil
          hours.sort.each do |start, finish|
            if not start =~ TIME_FORMAT
              raise InvalidConfiguration.new :invalid_format, data: { time: start }
            elsif not finish =~ TIME_FORMAT
              raise InvalidConfiguration.new :invalid_format, data: { time: finish }
            elsif compile_time(finish) >= 24 * 60 * 60
              raise InvalidConfiguration.new :outside_of_day, data: { time: finish }
            elsif start >= finish
              raise InvalidConfiguration.new :wrong_order, data: { start: start, finish: finish }
            elsif last_time and start < last_time
              raise InvalidConfiguration.new :overlap, data: { start: start, finish: finish }
            end
            last_time = finish
          end
        end
      end

      def validate_working_hours! week
        if week.empty?
          raise InvalidConfiguration.new :empty
        end
        if (invalid_keys = (week.keys - DAYS_OF_WEEK)).any?
          raise InvalidConfiguration.new :invalid_day_keys, data: { invalid_keys: invalid_keys.join(', ') }
        end
        validate_hours!(week)
      end

      def validate_holiday_hours! days
        if (invalid_keys = (days.keys.reject{ |day| day.is_a?(Date) })).any?
          raise InvalidConfiguration.new :invalid_holiday_keys, data: { invalid_keys: invalid_keys.join(', ') }
        end
        validate_hours!(days)
      end

      def validate_holidays! holidays
        if not holidays.respond_to?(:to_a)
          raise InvalidConfiguration.new :holidays_not_array, data: { holidays_class: holidays.class }
        end
        holidays.to_a.each do |day|
          if not day.is_a? Date
            raise InvalidConfiguration.new :holiday_not_date, data: { day: day }
          end
        end
      end

      def validate_time_zone! zone
        if zone.is_a? String
          res = ActiveSupport::TimeZone[zone]
          if res.nil?
            raise InvalidConfiguration.new :unknown_timezone, data: { zone: zone }
          end
        elsif zone.is_a? ActiveSupport::TimeZone
          res = zone
        else
          raise InvalidConfiguration.new :invalid_timezone, data: { zone: zone.inspect }
        end
        res
      end
    end

    private

    def initialize; end
  end
end
