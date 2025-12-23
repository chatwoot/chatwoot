require 'geocoder/results/base'

module Geocoder::Result
  class Mapbox < Base

    def coordinates
      data['geometry']['coordinates'].reverse.map(&:to_f)
    end

    def place_name
      data['text']
    end

    def street
      data['properties']['address']
    end

    def city
      context_part('place')
    end

    def state
      context_part('region')
    end

    def state_code
      value = context_part('region', 'short_code')
      value.split('-').last unless value.nil?
    end

    def postal_code
      context_part('postcode')
    end

    def country
      context_part('country')
    end

    def country_code
      value = context_part('country', 'short_code')
      value.upcase unless value.nil?
    end

    def neighborhood
      context_part('neighborhood')
    end

    def address
      [place_name, street, city, state, postal_code, country].compact.join(', ')
    end

    private

    def context_part(name, key = 'text')
      (context.detect { |c| c['id'] =~ Regexp.new(name) } || {})[key]
    end

    def context
      Array(data['context'])
    end
  end
end

