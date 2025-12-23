# encoding: utf-8
require 'geocoder/results/base'

module Geocoder::Result
  class BanDataGouvFr < Base

    STATE_CODE_MAPPINGS = {
      "Guadeloupe" => "01",
      "Martinique" => "02",
      "Guyane" => "03",
      "La Réunion" => "04",
      "Mayotte" => "06",
      "Île-de-France" => "11",
      "Centre-Val de Loire" => "24",
      "Bourgogne-Franche-Comté" => "27",
      "Normandie" => "28",
      "Hauts-de-France" => "32",
      "Grand Est" => "44",
      "Pays de la Loire" => "52",
      "Bretagne" => "53",
      "Nouvelle-Aquitaine" => "75",
      "Occitanie" => "76",
      "Auvergne-Rhône-Alpes" => "84",
      "Provence-Alpes-Côte d'Azur" => "93",
      "Corse" => "94"
    }.freeze

    #### BASE METHODS ####

    def self.response_attributes
      %w[limit attribution version licence type features center]
    end

    response_attributes.each do |a|
      unless method_defined?(a)
        define_method a do
          @data[a]
        end
      end
    end

    #### BEST RESULT ####

    def result
      features[0] if features.any?
    end

    #### GEOMETRY ####

    def geometry
      result['geometry'] if result
    end

    def precision
      geometry['type'] if geometry
    end

    def coordinates
      coords = geometry["coordinates"]
      return [coords[1].to_f, coords[0].to_f]
    end

    #### PROPERTIES ####

    # List of raw attrbutes returned by BAN data gouv fr API:
    #
    #   :id           =>    [string] UUID of the result, said to be not stable
    #                       atm, based on IGN reference (Institut national de
    #                       l'information géographique et forestière)
    #
    #   :type         =>    [string] result type (housenumber, street, city,
    #                       town, village, locality)
    #
    #   :score        =>    [float] value between 0 and 1 giving result's
    #                       relevancy
    #
    #   :housenumber  =>    [string] street number and extra information
    #                       (bis, ter, A, B)
    #
    #   :street       =>    [string] street name
    #
    #   :name         =>    [string] housenumber and street name
    #
    #   :postcode     =>    [string] city post code (used for mails by La Poste,
    #                       beware many cities got severeal postcodes)
    #
    #   :citycode     =>    [string] city code (INSEE reference,
    #                       consider it as a french institutional UUID)
    #
    #   :city         =>    [string] city name
    #
    #   :context      =>    [string] department code, department name and
    #                       region code
    #
    #   :label        =>    [string] full address without state, country name
    #                       and country code
    #
    # CITIES ONLY PROPERTIES
    #
    #   :adm_weight   =>    [string] administrative weight (importance) of
    #                       the city
    #
    #   :population   =>    [float] number of inhabitants with a 1000 factor
    #
    # For up to date doc (in french only) : https://adresse.data.gouv.fr/api/
    #
    def properties
      result['properties'] if result
    end

    # List of usable Geocoder results' methods
    #
    #   score                   =>    [float] result relevance 0 to 1
    #
    #   location_id             =>    [string] location's IGN UUID
    #
    #   result_type             =>    [string] housenumber / street / city
    #                                 / town / village / locality
    #
    #   international_address   =>    [string] full address with country code
    #
    #   national_address        =>    [string] full address with country code
    #
    #   street_address          =>    [string] housenumber + extra inf
    #                                 + street name
    #
    #   street_number           =>    [string] housenumber + extra inf
    #                                 (bis, ter, etc)
    #
    #   street_name             =>    [string] street's name
    #
    #   city_name               =>    [string] city's name
    #
    #   city_code               =>    [string] city's INSEE UUID
    #
    #   postal_code             =>    [string] city's postal code (used for mails)
    #
    #   context                 =>    [string] city's department code, department
    #                                  name and region name
    #
    #   demartment_name         =>    [string] city's department name
    #
    #   department_code         =>    [string] city's department INSEE UUID
    #
    #   region_name             =>    [string] city's region name
    #
    #   population              =>    [string] city's inhabitants count
    #
    #   administrative_weight   =>    [integer] city's importance on a scale
    #                                 from 6 (capital city) to 1 (regular village)
    #
    def score
      properties['score']
    end

    def location_id
      properties['id']
    end

    # Types
    #
    #   housenumber
    #   street
    #   city
    #   town
    #   village
    #   locality
    #
    def result_type
      properties['type']
    end

    def international_address
      "#{national_address}, #{country}"
    end

    def national_address
      properties['label']
    end

    def street_address
      properties['name']
    end

    def street_number
      properties['housenumber']
    end

    def street_name
      properties['street']
    end

    def city_name
      properties['city']
    end

    def city_code
      properties['citycode']
    end

    def postal_code
      properties['postcode']
    end

    def context
      properties['context'].split(/,/).map(&:strip)
    end

    def department_code
      context[0] if context.length > 0
    end

    # Monkey logic to handle fact Paris is both a city and a department
    # in Île-de-France region
    def department_name
      if context.length > 1
        if context[1] == "Île-de-France"
          "Paris"
        else
          context[1]
        end
      end
    end

    def region_name
      if context.length == 2 && context[1] == "Île-de-France"
        context[1]
      elsif context.length > 2
        context[2]
      end
    end

    def region_code
      STATE_CODE_MAPPINGS[region_name]
    end

    def country
      "France"
    end

    # Country code types
    #    FR : France
    #    GF : Guyane Française
    #    RE : Réunion
    #    NC : Nouvelle-Calédonie
    #    GP : Guadeloupe
    #    MQ : Martinique
    #    MU : Maurice
    #    PF : Polynésie française
    #
    # Will need refacto to handle different country codes, but BAN API
    # is currently mainly designed for geocode FR country code addresses
    def country_code
      "FR"
    end

    #### ALIAS METHODS ####

    alias_method :address, :international_address
    alias_method :street, :street_name
    alias_method :city, :city_name
    alias_method :state, :region_name
    alias_method :state_code, :region_code

    #### CITIES' METHODS ####

    def population
      (properties['population'].to_f * 1000).to_i if city?(result_type)
    end

    def administrative_weight
      properties['adm_weight'].to_i if city?(result_type)
    end

    private

    def city?(result_type)
      %w(village town city).include?(result_type)
    end

  end
end
