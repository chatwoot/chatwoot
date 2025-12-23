# frozen_string_literal: true

class Redis
  module Commands
    module Geo
      # Adds the specified geospatial items (latitude, longitude, name) to the specified key
      #
      # @param [String] key
      # @param [Array] member arguemnts for member or members: longitude, latitude, name
      # @return [Integer] number of elements added to the sorted set
      def geoadd(key, *member)
        send_command([:geoadd, key, *member])
      end

      # Returns geohash string representing position for specified members of the specified key.
      #
      # @param [String] key
      # @param [String, Array<String>] member one member or array of members
      # @return [Array<String, nil>] returns array containg geohash string if member is present, nil otherwise
      def geohash(key, member)
        send_command([:geohash, key, member])
      end

      # Query a sorted set representing a geospatial index to fetch members matching a
      # given maximum distance from a point
      #
      # @param [Array] args key, longitude, latitude, radius, unit(m|km|ft|mi)
      # @param ['asc', 'desc'] sort sort returned items from the nearest to the farthest
      #   or the farthest to the nearest relative to the center
      # @param [Integer] count limit the results to the first N matching items
      # @param ['WITHDIST', 'WITHCOORD', 'WITHHASH'] options to return additional information
      # @return [Array<String>] may be changed with `options`
      def georadius(*args, **geoptions)
        geoarguments = _geoarguments(*args, **geoptions)

        send_command([:georadius, *geoarguments])
      end

      # Query a sorted set representing a geospatial index to fetch members matching a
      # given maximum distance from an already existing member
      #
      # @param [Array] args key, member, radius, unit(m|km|ft|mi)
      # @param ['asc', 'desc'] sort sort returned items from the nearest to the farthest or the farthest
      #   to the nearest relative to the center
      # @param [Integer] count limit the results to the first N matching items
      # @param ['WITHDIST', 'WITHCOORD', 'WITHHASH'] options to return additional information
      # @return [Array<String>] may be changed with `options`
      def georadiusbymember(*args, **geoptions)
        geoarguments = _geoarguments(*args, **geoptions)

        send_command([:georadiusbymember, *geoarguments])
      end

      # Returns longitude and latitude of members of a geospatial index
      #
      # @param [String] key
      # @param [String, Array<String>] member one member or array of members
      # @return [Array<Array<String>, nil>] returns array of elements, where each
      #   element is either array of longitude and latitude or nil
      def geopos(key, member)
        send_command([:geopos, key, member])
      end

      # Returns the distance between two members of a geospatial index
      #
      # @param [String ]key
      # @param [Array<String>] members
      # @param ['m', 'km', 'mi', 'ft'] unit
      # @return [String, nil] returns distance in spefied unit if both members present, nil otherwise.
      def geodist(key, member1, member2, unit = 'm')
        send_command([:geodist, key, member1, member2, unit])
      end

      private

      def _geoarguments(*args, options: nil, sort: nil, count: nil)
        args << sort if sort
        args << 'COUNT' << Integer(count) if count
        args << options if options
        args
      end
    end
  end
end
