module TelephoneNumber
  class Number
    extend Forwardable

    attr_reader :country, :parser, :formatter, :original_number, :geo_locator, :time_zone_detector

    delegate [:valid?, :valid_types, :normalized_number] => :parser
    delegate [:national_number, :e164_number, :international_number] => :formatter

    def initialize(number, country = nil)
      @original_number = TelephoneNumber.sanitize(number)
      @country = country ? Country.find(country) : detect_country
      @parser = Parser.new(self)
      @formatter = Formatter.new(self)
    end

    def location(locale = :en)
      return if !country || !valid?
      @geo_locator ||= GeoLocator.new(self, locale)
      @geo_locator.location
    end

    def timezone
      return if !country || !valid?
      @time_zone_detector ||= TimeZoneDetector.new(self)
      @time_zone_detector.detect_timezone
    end

    private

    def eligible_countries
      # note that it is entirely possible for two separate countries to use the same
      # validation scheme. Take Italy and Vatican City for example.
      Country.all_countries.select do |country|
        original_number.start_with?(country.country_code) && self.class.new(original_number, country.country_id).valid?
      end
    end

    def detect_country
      eligible_countries.detect(&:main_country_for_code) || eligible_countries.first
    end
  end
end
