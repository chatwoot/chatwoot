# frozen_string_literal: true

module Faker
  class Address < Base
    flexible :address

    class << self
      ##
      # Produces the name of a city.
      #
      # @param options [Hash]
      # @option with_state [Boolean] Whether to include the state name in the output.
      # @return [String]
      #
      # @example
      #   Faker::Address.city #=> "Imogeneborough"
      #   Faker::Address.city(options: { with_state: true })
      #     #=> "Northfort, California"
      #
      # @faker.version 0.3.0
      def city(options: {})
        parse(options[:with_state] ? 'address.city_with_state' : 'address.city')
      end

      ##
      # Produces a street name.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.street_name #=> "Larkin Fork"
      #
      # @faker.version 0.3.0
      def street_name
        parse('address.street_name')
      end

      ##
      # Produces a street address.
      #
      # @param include_secondary [Boolean] Whether or not to include the secondary address.
      # @return [String]
      #
      # @example
      #   Faker::Address.street_address #=> "282 Kevin Brook"
      #
      # @faker.version 0.3.0
      def street_address(include_secondary: false)
        numerify(parse('address.street_address') + (include_secondary ? " #{secondary_address}" : ''))
      end

      ##
      # Produces a secondary address.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.secondary_address #=> "Apt. 672"
      #
      # @faker.version 0.3.0
      def secondary_address
        bothify(fetch('address.secondary_address'))
      end

      ##
      # Produces a building number.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.building_number #=> "7304"
      #
      # @faker.version 0.3.0
      def building_number
        bothify(fetch('address.building_number'))
      end

      ##
      # Produces the name of a community.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.community #=> "University Crossing"
      #
      # @faker.version 1.8.0
      def community
        parse('address.community')
      end

      ##
      #
      # Produces a mail box number.
      # @return [String]
      #
      # @example
      #   Faker::Address.mail_box #=> "PO Box 123"
      #
      # @faker.version 2.9.1
      def mail_box
        bothify(fetch('address.mail_box'))
      end

      ##
      # Produces a Zip Code.
      #
      # @param state_abbreviation [String] an abbreviation for a state where the zip code should be located.
      # @return [String]
      #
      # @example
      #   Faker::Address.zip_code #=> "58517"
      #   Faker::Address.zip_code #=> "23285-4905"
      #   Faker::Address.zip_code(state_abbreviation: 'CO') #=> "80011"
      #
      # @faker.version 0.3.0
      def zip_code(state_abbreviation: '')
        if state_abbreviation.empty?
          letterified_string = letterify(fetch('address.postcode'))
          return numerify(letterified_string, leading_zero: true)
        end

        # provide a zip code that is valid for the state provided
        # see http://www.fincen.gov/forms/files/us_state_territory_zip_codes.pdf
        bothify(fetch("address.postcode_by_state.#{state_abbreviation}"))
      end

      ##
      # Produces the name of a time zone.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.time_zone #=> "Asia/Yakutsk"
      #
      # @faker.version 1.2.0
      def time_zone
        fetch('address.time_zone')
      end

      alias zip zip_code
      alias postcode zip_code

      ##
      # Produces a street suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.street_suffix #=> "Street"
      #
      # @faker.version 0.3.0
      def street_suffix
        fetch('address.street_suffix')
      end

      ##
      # Produces a city suffix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.city_suffix #=> "fort"
      #
      # @faker.version 0.3.0
      def city_suffix
        fetch('address.city_suffix')
      end

      ##
      # Produces a city prefix.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.city_prefix #=> "Lake"
      #
      # @faker.version 0.3.0
      def city_prefix
        fetch('address.city_prefix')
      end

      ##
      # Produces a state abbreviation.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.state_abbr #=> "AP"
      #
      # @faker.version 0.3.0
      def state_abbr
        fetch('address.state_abbr')
      end

      ##
      # Produces the name of a state.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.state #=> "California"
      #
      # @faker.version 0.3.0
      def state
        fetch('address.state')
      end

      ##
      # Produces the name of a country.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.country #=> "French Guiana"
      #
      # @faker.version 0.3.0
      def country
        fetch('address.country')
      end

      ##
      # Produces a country by ISO country code. See the
      # [List of ISO 3166 country codes](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes)
      # on Wikipedia for a full list.
      #
      # @param code [String] An ISO country code.
      # @return [String]
      #
      # @example
      #   Faker::Address.country_by_code(code: 'NL') #=> "Netherlands"
      #
      # @faker.version 1.9.2
      def country_by_code(code: 'US')
        fetch("address.country_by_code.#{code}")
      end

      ##
      # Produces an ISO 3166 country code when given a country name.
      #
      # @param name [String] Country name in snake_case format.
      # @return [String]
      #
      # @example
      #   Faker::Address.country_name_to_code(name: 'united_states') #=> "US"
      #
      # @faker.version 1.9.2
      def country_name_to_code(name: 'united_states')
        fetch("address.country_by_name.#{name}")
      end

      ##
      # Produces an ISO 3166 country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.country_code #=> "IT"
      #
      # @faker.version 1.4.0
      def country_code
        fetch('address.country_code')
      end

      ##
      # Produces a long (alpha-3) ISO 3166 country code.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.country_code_long #=> "ITA"
      #
      # @faker.version 0.3.0
      def country_code_long
        fetch('address.country_code_long')
      end

      ##
      # Produces a latitude.
      #
      # @return [Float]
      #
      # @example
      #   Faker::Address.latitude #=> -58.17256227443719
      #
      # @faker.version 1.0.0
      def latitude
        ((rand * 180) - 90).to_f
      end

      ##
      # Produces a longitude.
      #
      # @return [Float]
      #
      # @example
      #   Faker::Address.longitude #=> -156.65548382095133
      #
      # @faker.version 1.0.0
      def longitude
        ((rand * 360) - 180).to_f
      end

      ##
      # Produces a full address.
      #
      # @return [String]
      #
      # @example
      #   Faker::Address.full_address
      #     #=> "282 Kevin Brook, Imogeneborough, CA 58517"
      #
      # @faker.version 0.3.0
      def full_address
        parse('address.full_address')
      end

      ##
      # Produces Address hash of required fields
      #
      # @return [Hash]
      #
      # @example
      #   Faker::Address.full_address_as_hash(:longitude,
      #                                       :latitude,
      #                                       :country_name_to_code,
      #                                       country_name_to_code: {name: 'united_states'})
      #     #=> {:longitude=>-101.74428917174603, :latitude=>-37.40056749089944, :country_name_to_code=>"US"}
      #
      #  Faker::Address.full_address_as_hash(:full_address)
      #     #=> {:full_address=>"87635 Rice Street, Lake Brentonton, OR 61896-5968"}
      #
      #  Faker::Address.full_address_as_hash(:city, :time_zone)
      #     #=> {:city=>"East Faustina", :time_zone=>"America/Mexico_City"}
      #
      #  Faker::Address.full_address_as_hash(:street_address, street_address: {include_secondary: true})
      #     #=> {:street_address=>"29423 Kenneth Causeway Suite 563"}
      #
      # @faker.version 2.13.0
      def full_address_as_hash(*attrs, **attrs_params)
        attrs.map!(&:to_sym)
        attrs_params.transform_keys!(&:to_sym)
        attrs.map do |attr|
          { "#{attr}": attrs_params[attr] ? send(attr, **attrs_params[attr]) : send(attr) }
        end.reduce({}, :merge)
      end
    end
  end
end
