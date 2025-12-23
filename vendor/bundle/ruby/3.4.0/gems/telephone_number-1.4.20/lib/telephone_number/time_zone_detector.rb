module TelephoneNumber
  class TimeZoneDetector
    attr_reader :phone_number, :timezone

    def initialize(phone_number)
      @phone_number = phone_number
    end

    def detect_timezone
      normalized_number = build_normalized_number.dup
      timezone = nil
      (normalized_number.length - 2).times { break if timezone = data[normalized_number.chop!] }
      timezone.to_s.split('&').join(', ')
    end

    def data
      @data ||= Marshal.load(File.binread(File.expand_path('../../../data/timezones/map_data.dat', __FILE__)))
    end

    private

    # Google's geocoding data is odd in that it uses a non-standard format for lookups
    # on countries that have a mobile token. While I don't believe that this is used right now
    # it will be if/when Google adds more specific data for Argentina. This method safe guards
    # against that.
    def build_normalized_number
      return phone_number.e164_number(formatted: false) unless mobile_token = phone_number.country.mobile_token
      if phone_number.parser.normalized_number.start_with?(mobile_token)
        phone_number.e164_number(formatted: false).sub(mobile_token, '')
      else
        phone_number.e164_number(formatted: false)
      end
    end
  end
end
