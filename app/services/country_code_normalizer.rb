require 'tzinfo'

class CountryCodeNormalizer
  COUNTRY_ALIASES = {
    'united states of america' => 'US',
    'usa' => 'US',
    'uk' => 'GB',
    'united kingdom' => 'GB'
  }.freeze

  class << self
    def normalize(value)
      return if value.blank?

      value = value.to_s.strip
      code = value.upcase
      return code if country_by_code.key?(code)

      country_by_name[normalized_name(value)] || COUNTRY_ALIASES[normalized_name(value)]
    end

    def name_for(code)
      country_by_code[normalize(code)]&.name
    end

    private

    def country_by_code
      @country_by_code ||= TZInfo::Country.all_codes.index_with { |code| TZInfo::Country.get(code) }
    end

    def country_by_name
      @country_by_name ||= country_by_code.each_with_object({}) do |(code, country), result|
        result[normalized_name(country.name)] = code
      end
    end

    def normalized_name(value)
      value.to_s.strip.downcase
    end
  end
end
