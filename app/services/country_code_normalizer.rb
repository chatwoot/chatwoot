require 'tzinfo'

class CountryCodeNormalizer
  COUNTRY_ALIASES = {
    'aland islands' => 'AX',
    'americansamoa' => 'AS',
    'antigua and barbuda' => 'AG',
    'bolivia, plurinational state of' => 'BO',
    'bosnia and herzegovina' => 'BA',
    'brunei darussalam' => 'BN',
    'central african republic' => 'CF',
    'congo' => 'CG',
    'congo, the democratic republic of the congo' => 'CD',
    "cote d'ivoire" => 'CI',
    'falkland islands (malvinas)' => 'FK',
    'holy see (vatican city state)' => 'VA',
    'iran, islamic republic of persian gulf' => 'IR',
    "korea, democratic people's republic of korea" => 'KP',
    'korea, republic of south korea' => 'KR',
    'libyan arab jamahiriya' => 'LY',
    'macao' => 'MO',
    'macedonia' => 'MK',
    'micronesia, federated states of micronesia' => 'FM',
    'myanmar' => 'MM',
    'netherlands antilles' => 'AN',
    'palestinian territory, occupied' => 'PS',
    'reunion' => 'RE',
    'saint barthelemy' => 'BL',
    'saint helena, ascension and tristan da cunha' => 'SH',
    'saint kitts and nevis' => 'KN',
    'saint lucia' => 'LC',
    'saint martin' => 'MF',
    'saint pierre and miquelon' => 'PM',
    'saint vincent and the grenadines' => 'VC',
    'samoa' => 'WS',
    'sao tome and principe' => 'ST',
    'south georgia and the south sandwich islands' => 'GS',
    'svalbard and jan mayen' => 'SJ',
    'swaziland' => 'SZ',
    'syrian arab republic' => 'SY',
    'tanzania, united republic of tanzania' => 'TZ',
    'timor-leste' => 'TL',
    'trinidad and tobago' => 'TT',
    'turks and caicos islands' => 'TC',
    'venezuela, bolivarian republic of venezuela' => 'VE',
    'virgin islands, british' => 'VG',
    'virgin islands, u.s.' => 'VI',
    'wallis and futuna' => 'WF',
    'united states of america' => 'US',
    'usa' => 'US',
    'uk' => 'GB',
    'united kingdom' => 'GB'
  }.freeze

  class << self
    def normalize(value)
      country_codes_by_value[normalized_name(value)]
    end

    def name_for(code)
      code = normalize(code)
      return 'Netherlands Antilles' if code == 'AN'

      country_by_code[code]&.name
    end

    def country_codes_by_value
      @country_codes_by_value ||= begin
        # Include the retired code still emitted by the country selector.
        codes = (country_by_code.keys + ['AN']).index_by(&:downcase)
        country_by_name.merge(COUNTRY_ALIASES).merge(codes)
      end
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
