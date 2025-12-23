require 'geocoder/results/base'

module Geocoder::Result
  class Photon < Base
    def name
      properties['name']
    end

    def address(_format = :full)
      parts = []
      parts << name if name
      parts << street_address if street_address
      parts << city
      parts << state if state
      parts << postal_code
      parts << country

      parts.join(', ')
    end

    def street_address
      return unless street
      return street unless house_number

      "#{house_number} #{street}"
    end

    def house_number
      properties['housenumber']
    end

    def street
      properties['street']
    end

    def postal_code
      properties['postcode']
    end

    def city
      properties['city']
    end

    def state
      properties['state']
    end

    def state_code
      ''
    end

    def country
      properties['country']
    end

    def country_code
      ''
    end

    def coordinates
      return unless geometry
      return unless geometry[:coordinates]

      geometry[:coordinates].reverse
    end

    def geometry
      return unless data['geometry']

      symbol_hash data['geometry']
    end

    def bounds
      properties['extent']
    end

    # Type of the result (OSM object type), one of:
    #
    #   :node
    #   :way
    #   :relation
    #
    def type
      {
        'N' => :node,
        'W' => :way,
        'R' => :relation
      }[properties['osm_type']]
    end

    def osm_id
      properties['osm_id']
    end

    # See: https://wiki.openstreetmap.org/wiki/Tags
    def osm_tag
      return unless properties['osm_key']
      return properties['osm_key'] unless properties['osm_value']

      "#{properties['osm_key']}=#{properties['osm_value']}"
    end

    private

    def properties
      @properties ||= data['properties'] || {}
    end

    def symbol_hash(orig_hash)
      {}.tap do |result|
        orig_hash.each_key do |key|
          next unless orig_hash[key]

          result[key.to_sym] = orig_hash[key]
        end
      end
    end
  end
end
