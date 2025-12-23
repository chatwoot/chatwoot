require 'time'

module SafeYAML
  class Parse
    class Date
      # This one's easy enough :)
      DATE_MATCHER = /\A(\d{4})-(\d{2})-(\d{2})\Z/.freeze

      # This unbelievable little gem is taken basically straight from the YAML spec, but made
      # slightly more readable (to my poor eyes at least) to me:
      # http://yaml.org/type/timestamp.html
      TIME_MATCHER = /\A\d{4}-\d{1,2}-\d{1,2}(?:[Tt]|\s+)\d{1,2}:\d{2}:\d{2}(?:\.\d*)?\s*(?:Z|[-+]\d{1,2}(?::?\d{2})?)?\Z/.freeze

      SECONDS_PER_DAY = 60 * 60 * 24
      MICROSECONDS_PER_SECOND = 1000000

      # So this is weird. In Ruby 1.8.7, the DateTime#sec_fraction method returned fractional
      # seconds in units of DAYS for some reason. In 1.9.2, they changed the units -- much more
      # reasonably -- to seconds.
      SEC_FRACTION_MULTIPLIER = RUBY_VERSION == "1.8.7" ? (SECONDS_PER_DAY * MICROSECONDS_PER_SECOND) : MICROSECONDS_PER_SECOND

      # The DateTime class has a #to_time method in Ruby 1.9+;
      # Before that we'll just need to convert DateTime to Time ourselves.
      TO_TIME_AVAILABLE = DateTime.instance_methods.include?(:to_time)

      def self.value(value)
        d = DateTime.parse(value)

        return d.to_time if TO_TIME_AVAILABLE

        usec = d.sec_fraction * SEC_FRACTION_MULTIPLIER
        time = Time.utc(d.year, d.month, d.day, d.hour, d.min, d.sec, usec) - (d.offset * SECONDS_PER_DAY)
        time.getlocal
      end
    end
  end
end
