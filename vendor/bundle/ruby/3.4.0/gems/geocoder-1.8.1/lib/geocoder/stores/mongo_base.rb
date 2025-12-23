module Geocoder::Store
  module MongoBase

    def self.included_by_model(base)
      base.class_eval do

        scope :geocoded, lambda {
          where(geocoder_options[:coordinates].ne => nil)
        }

        scope :not_geocoded, lambda {
          where(geocoder_options[:coordinates] => nil)
        }
      end
    end

    ##
    # Coordinates [lat,lon] of the object.
    # This method always returns coordinates in lat,lon order,
    # even though internally they are stored in the opposite order.
    #
    def to_coordinates
      coords = send(self.class.geocoder_options[:coordinates])
      coords.is_a?(Array) ? coords.reverse : []
    end

    ##
    # Look up coordinates and assign to +latitude+ and +longitude+ attributes
    # (or other as specified in +geocoded_by+). Returns coordinates (array).
    #
    def geocode
      do_lookup(false) do |o,rs|
        if r = rs.first
          unless r.coordinates.nil?
            o.__send__ "#{self.class.geocoder_options[:coordinates]}=", r.coordinates.reverse
          end
          r.coordinates
        end
      end
    end

    ##
    # Look up address and assign to +address+ attribute (or other as specified
    # in +reverse_geocoded_by+). Returns address (string).
    #
    def reverse_geocode
      do_lookup(true) do |o,rs|
        if r = rs.first
          unless r.address.nil?
            o.__send__ "#{self.class.geocoder_options[:fetched_address]}=", r.address
          end
          r.address
        end
      end
    end
  end
end

