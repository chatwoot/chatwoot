require 'geocoder/lookups/base'
require 'geocoder/results/geoip2'

module Geocoder
  module Lookup
    class Geoip2 < Base
      attr_reader :gem_name

      def initialize
        unless configuration[:file].nil?
          begin
            @gem_name = configuration[:lib] || 'maxminddb'
            require @gem_name
          rescue LoadError
            raise "Could not load Maxmind DB dependency. To use the GeoIP2 lookup you must add the #{@gem_name} gem to your Gemfile or have it installed in your system."
          end

          @mmdb = db_class.new(configuration[:file].to_s)
        end
        super
      end

      def name
        'GeoIP2'
      end

      def required_api_key_parts
        []
      end

      private

      def db_class
        gem_name == 'hive_geoip2' ? Hive::GeoIP2 : MaxMindDB
      end

      def results(query)
        return [] unless configuration[:file]

        if @mmdb.respond_to?(:local_ip_alias) && !configuration[:local_ip_alias].nil?
          @mmdb.local_ip_alias = configuration[:local_ip_alias]
        end

        result = @mmdb.lookup(query.to_s)
        result.nil? ? [] : [result]
      end
    end
  end
end
