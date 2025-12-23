module TelephoneNumber
  class GeoLocator
    attr_reader :phone_number, :normalized_number, :location, :locale

    # initialize with a phone_number object
    def initialize(phone_number, locale)
      @phone_number = phone_number
      @normalized_number = build_normalized_number
      @locale = locale
    end

    def location
      @location ||= find_location
    end

    def location_data
      @location_data ||= fetch_location_data
    end

    private

    def find_location
      number = normalized_number.dup
      location = nil
      (number.length - 2).times { break if location = location_data[number.chop!] }
      location
    end

    def fetch_location_data
      return {} unless location_file = find_location_file
      Marshal.load(File.binread(location_file))
    end

    def find_location_file
      locale_path = geocoding_path(locale)
      path = locale_path.empty? ? geocoding_path(:en) : locale_path

      path.sort { |a, b| b <=> a }.detect do |path|
        normalized_number.match?(/^#{File.basename(path, 'dat')}/)
      end
    end

    def geocoding_path(locale)
      path = File.expand_path("../../../data/geocoding/#{locale}/*.dat", __FILE__)
      Dir.glob(path)
    end

    # Google's geocoding data is odd in that it uses a non-standard format for lookups
    # on countries that have a mobile token. In short, we need to remove it. See the link
    # below for reference.
    # https://github.com/googlei18n/libphonenumber/blob/master/java/geocoder/src/com/google/i18n/phonenumbers/geocoding/PhoneNumberOfflineGeocoder.java#L121
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
