require 'geocoder/results/base'

module Geocoder::Result
  class Yandex < Base
    # Yandex result has difficult tree structure,
    # and presence of some nodes depends on exact search case.

    # Also Yandex lacks documentation about it.
    # See https://tech.yandex.com/maps/doc/geocoder/desc/concepts/response_structure-docpage/

    # Ultimatly, we need to find Locality and/or Thoroughfare data.

    # It may resides on the top (ADDRESS_DETAILS) level.
    # example: 'Baltic Sea'
    # "AddressDetails": {
    #   "Locality": {
    #     "Premise": {
    #       "PremiseName": "Baltic Sea"
    #     }
    #   }
    # }

    ADDRESS_DETAILS = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails
    ].freeze

    # On COUNTRY_LEVEL.
    # example: 'Potomak'
    # "AddressDetails": {
    #   "Country": {
    #     "AddressLine": "reka Potomak",
    #     "CountryNameCode": "US",
    #     "CountryName": "United States of America",
    #     "Locality": {
    #       "Premise": {
    #         "PremiseName": "reka Potomak"
    #       }
    #     }
    #   }
    # }

    COUNTRY_LEVEL = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails Country
    ].freeze

    # On ADMIN_LEVEL (usually state or city)
    # example: 'Moscow, Tverskaya'
    # "AddressDetails": {
    #   "Country": {
    #     "AddressLine": "Moscow, Tverskaya Street",
    #     "CountryNameCode": "RU",
    #     "CountryName": "Russia",
    #     "AdministrativeArea": {
    #       "AdministrativeAreaName": "Moscow",
    #       "Locality": {
    #         "LocalityName": "Moscow",
    #         "Thoroughfare": {
    #           "ThoroughfareName": "Tverskaya Street"
    #         }
    #       }
    #     }
    #   }
    # }

    ADMIN_LEVEL = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails Country
      AdministrativeArea
    ].freeze

    # On SUBADMIN_LEVEL (may refer to urban district)
    # example: 'Moscow Region, Krasnogorsk'
    # "AddressDetails": {
    #   "Country": {
    #     "AddressLine": "Moscow Region, Krasnogorsk",
    #     "CountryNameCode": "RU",
    #     "CountryName": "Russia",
    #     "AdministrativeArea": {
    #       "AdministrativeAreaName": "Moscow Region",
    #       "SubAdministrativeArea": {
    #         "SubAdministrativeAreaName": "gorodskoy okrug Krasnogorsk",
    #         "Locality": {
    #           "LocalityName": "Krasnogorsk"
    #         }
    #       }
    #     }
    #   }
    # }

    SUBADMIN_LEVEL = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails Country
      AdministrativeArea
      SubAdministrativeArea
    ].freeze

    # On DEPENDENT_LOCALITY_1 (may refer to district of city)
    # example: 'Paris, Etienne Marcel'
    # "AddressDetails": {
    #   "Country": {
    #     "AddressLine": "Île-de-France, Paris, 1er Arrondissement, Rue Étienne Marcel",
    #     "CountryNameCode": "FR",
    #     "CountryName": "France",
    #     "AdministrativeArea": {
    #       "AdministrativeAreaName": "Île-de-France",
    #       "Locality": {
    #         "LocalityName": "Paris",
    #         "DependentLocality": {
    #           "DependentLocalityName": "1er Arrondissement",
    #           "Thoroughfare": {
    #             "ThoroughfareName": "Rue Étienne Marcel"
    #           }
    #         }
    #       }
    #     }
    #   }
    # }

    DEPENDENT_LOCALITY_1 = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails Country
      AdministrativeArea Locality
      DependentLocality
    ].freeze

    # On DEPENDENT_LOCALITY_2 (for special cases like turkish "mahalle")
    # https://en.wikipedia.org/wiki/Mahalle
    # example: 'Istanbul Mabeyinci Yokuşu 17'

    # "AddressDetails": {
    #   "Country": {
    #     "AddressLine": "İstanbul, Fatih, Saraç İshak Mah., Mabeyinci Yokuşu, 17",
    #     "CountryNameCode": "TR",
    #     "CountryName": "Turkey",
    #     "AdministrativeArea": {
    #       "AdministrativeAreaName": "İstanbul",
    #       "SubAdministrativeArea": {
    #         "SubAdministrativeAreaName": "Fatih",
    #         "Locality": {
    #           "DependentLocality": {
    #             "DependentLocalityName": "Saraç İshak Mah.",
    #             "Thoroughfare": {
    #               "ThoroughfareName": "Mabeyinci Yokuşu",
    #               "Premise": {
    #                 "PremiseNumber": "17"
    #               }
    #             }
    #           }
    #         }
    #       }
    #     }
    #   }
    # }

    DEPENDENT_LOCALITY_2 = %w[
      GeoObject metaDataProperty GeocoderMetaData
      AddressDetails Country
      AdministrativeArea
      SubAdministrativeArea Locality
      DependentLocality
    ].freeze

    def coordinates
      @data['GeoObject']['Point']['pos'].split(' ').reverse.map(&:to_f)
    end

    def address(_format = :full)
      @data['GeoObject']['metaDataProperty']['GeocoderMetaData']['text']
    end

    def city
      result =
        if state.empty?
          find_in_hash(@data, *COUNTRY_LEVEL, 'Locality', 'LocalityName')
        elsif sub_state.empty?
          find_in_hash(@data, *ADMIN_LEVEL, 'Locality', 'LocalityName')
        else
          find_in_hash(@data, *SUBADMIN_LEVEL, 'Locality', 'LocalityName')
        end

      result || ""
    end

    def country
      find_in_hash(@data, *COUNTRY_LEVEL, 'CountryName') || ""
    end

    def country_code
      find_in_hash(@data, *COUNTRY_LEVEL, 'CountryNameCode') || ""
    end

    def state
      find_in_hash(@data, *ADMIN_LEVEL, 'AdministrativeAreaName') || ""
    end

    def sub_state
      return "" if state.empty?
      find_in_hash(@data, *SUBADMIN_LEVEL, 'SubAdministrativeAreaName') || ""
    end

    def state_code
      ""
    end

    def street
      thoroughfare_data.is_a?(Hash) ? thoroughfare_data['ThoroughfareName'] : ""
    end

    def street_number
      premise.is_a?(Hash) ? premise.fetch('PremiseNumber', "") : ""
    end

    def premise_name
      premise.is_a?(Hash) ? premise.fetch('PremiseName', "") : ""
    end

    def postal_code
      return "" unless premise.is_a?(Hash)
      find_in_hash(premise, 'PostalCode', 'PostalCodeNumber') || ""
    end

    def kind
      @data['GeoObject']['metaDataProperty']['GeocoderMetaData']['kind']
    end

    def precision
      @data['GeoObject']['metaDataProperty']['GeocoderMetaData']['precision']
    end

    def viewport
      envelope = @data['GeoObject']['boundedBy']['Envelope'] || fail
      east, north = envelope['upperCorner'].split(' ').map(&:to_f)
      west, south = envelope['lowerCorner'].split(' ').map(&:to_f)
      [south, west, north, east]
    end

    private # ----------------------------------------------------------------

    def top_level_locality
      find_in_hash(@data, *ADDRESS_DETAILS, 'Locality')
    end

    def country_level_locality
      find_in_hash(@data, *COUNTRY_LEVEL, 'Locality')
    end

    def admin_locality
      find_in_hash(@data, *ADMIN_LEVEL, 'Locality')
    end

    def subadmin_locality
      find_in_hash(@data, *SUBADMIN_LEVEL, 'Locality')
    end

    def dependent_locality
      find_in_hash(@data, *DEPENDENT_LOCALITY_1) ||
        find_in_hash(@data, *DEPENDENT_LOCALITY_2)
    end

    def locality_data
      dependent_locality || subadmin_locality || admin_locality ||
        country_level_locality || top_level_locality
    end

    def thoroughfare_data
      locality_data['Thoroughfare'] if locality_data.is_a?(Hash)
    end

    def premise
      if thoroughfare_data.is_a?(Hash)
        thoroughfare_data['Premise']
      elsif locality_data.is_a?(Hash)
        locality_data['Premise']
      end
    end

    def find_in_hash(source, *keys)
      key = keys.shift
      result = source[key]

      if keys.empty?
        return result
      elsif !result.is_a?(Hash)
        return nil
      end

      find_in_hash(result, *keys)
    end
  end
end
