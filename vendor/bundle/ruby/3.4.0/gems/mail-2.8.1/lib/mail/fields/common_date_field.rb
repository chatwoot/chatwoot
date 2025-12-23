require 'mail/fields/named_structured_field'
require 'mail/elements/date_time_element'
require 'mail/utilities'

module Mail
  class CommonDateField < NamedStructuredField #:nodoc:
    def self.singular?
      true
    end

    def self.normalize_datetime(string)
      if Utilities.blank?(string)
        datetime = ::DateTime.now
      else
        stripped = string.to_s.gsub(/\(.*?\)/, '').squeeze(' ')
        begin
          datetime = ::DateTime.parse(stripped)
        rescue ArgumentError => e
          raise unless 'invalid date' == e.message
        end
      end

      if datetime
        datetime.strftime('%a, %d %b %Y %H:%M:%S %z')
      else
        string
      end
    end

    def initialize(value = nil, charset = nil)
      super self.class.normalize_datetime(value), charset
    end

    # Returns a date time object of the parsed date
    def date_time
      ::DateTime.parse("#{element.date_string} #{element.time_string}")
    rescue ArgumentError => e
      raise e unless e.message == 'invalid date'
    end

    def default
      date_time
    end

    def element
      @element ||= Mail::DateTimeElement.new(value)
    end

    private
      def do_encode
        "#{name}: #{value}\r\n"
      end

      def do_decode
        value.to_s
      end
  end
end
