require "geocoder/lookups/test"

module Geocoder
  module Lookup
    extend self

    ##
    # Array of valid Lookup service names.
    #
    def all_services
      street_services + ip_services
    end

    ##
    # Array of valid Lookup service names, excluding :test.
    #
    def all_services_except_test
      all_services - [:test]
    end

    ##
    # Array of valid Lookup service names, excluding any that do not build their own HTTP requests.
    # For example, Amazon Location Service uses the AWS gem, not HTTP REST requests, to fetch data.
    #
    def all_services_with_http_requests
      all_services_except_test - [:amazon_location_service]
    end

    ##
    # All street address lookup services, default first.
    #
    def street_services
      @street_services ||= [
        :location_iq,
        :dstk,
        :esri,
        :google,
        :google_premier,
        :google_places_details,
        :google_places_search,
        :bing,
        :geocoder_ca,
        :yandex,
        :nationaal_georegister_nl,
        :nominatim,
        :mapbox,
        :mapquest,
        :uk_ordnance_survey_names,
        :opencagedata,
        :pelias,
        :pickpoint,
        :here,
        :baidu,
        :tencent,
        :geocodio,
        :smarty_streets,
        :postcode_anywhere_uk,
        :postcodes_io,
        :geoportail_lu,
        :ban_data_gouv_fr,
        :test,
        :latlon,
        :amap,
        :osmnames,
        :melissa_street,
        :amazon_location_service,
        :geoapify,
        :photon,
        :twogis
      ]
    end

    ##
    # All IP address lookup services, default first.
    #
    def ip_services
      @ip_services ||= [
        :baidu_ip,
        :abstract_api,
        :freegeoip,
        :geoip2,
        :maxmind,
        :maxmind_local,
        :telize,
        :pointpin,
        :maxmind_geoip2,
        :ipinfo_io,
        :ipregistry,
        :ipapi_com,
        :ipdata_co,
        :db_ip_com,
        :ipstack,
        :ip2location,
        :ipgeolocation,
        :ipqualityscore,
        :ipbase
      ]
    end

    attr_writer :street_services, :ip_services

    ##
    # Retrieve a Lookup object from the store.
    # Use this instead of Geocoder::Lookup::X.new to get an
    # already-configured Lookup object.
    #
    def get(name)
      @services = {} unless defined?(@services)
      @services[name] = spawn(name) unless @services.include?(name)
      @services[name]
    end


    private # -----------------------------------------------------------------

    ##
    # Spawn a Lookup of the given name.
    #
    def spawn(name)
      if all_services.include?(name)
        name = name.to_s
        instantiate_lookup(name)
      else
        valids = all_services.map(&:inspect).join(", ")
        raise ConfigurationError, "Please specify a valid lookup for Geocoder " +
          "(#{name.inspect} is not one of: #{valids})."
      end
    end

    ##
    # Convert an "underscore" version of a name into a "class" version.
    #
    def classify_name(filename)
      filename.to_s.split("_").map{ |i| i[0...1].upcase + i[1..-1] }.join
    end

    ##
    # Safely instantiate Lookup
    #
    def instantiate_lookup(name)
      class_name = classify_name(name)
      begin
        Geocoder::Lookup.const_get(class_name, inherit=false)
      rescue NameError
        require "geocoder/lookups/#{name}"
      end
      Geocoder::Lookup.const_get(class_name).new
    end
  end
end
