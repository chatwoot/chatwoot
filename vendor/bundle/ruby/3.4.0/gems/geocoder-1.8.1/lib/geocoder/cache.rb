Dir["#{__dir__}/cache_stores/*.rb"].each {|file| require file }

module Geocoder
  class Cache

    def initialize(store, config)
      @class = (Object.const_get("Geocoder::CacheStore::#{store.class}") rescue Geocoder::CacheStore::Generic)
      @store_service = @class.new(store, config)
    end

    ##
    # Read from the Cache.
    #
    def [](url)
      interpret store_service.read(url)
    rescue => e
      Geocoder.log(:warn, "Geocoder cache read error: #{e}")
    end

    ##
    # Write to the Cache.
    #
    def []=(url, value)
      store_service.write(url, value)
    rescue => e
      Geocoder.log(:warn, "Geocoder cache write error: #{e}")
    end

    ##
    # Delete cache entry for given URL,
    # or pass <tt>:all</tt> to clear all URLs.
    #
    def expire(url)
      if url == :all
        if store_service.respond_to?(:keys)
          urls.each{ |u| expire(u) }
        else
          raise(NoMethodError, "The Geocoder cache store must implement `#keys` for `expire(:all)` to work")
        end
      else
        expire_single_url(url)
      end
    end


    private # ----------------------------------------------------------------

    def store_service; @store_service; end

    ##
    # Array of keys with the currently configured prefix
    # that have non-nil values.
    #
    def keys
      store_service.keys
    end

    ##
    # Array of cached URLs.
    #
    def urls
      store_service.urls
    end

    ##
    # Clean up value before returning. Namely, convert empty string to nil.
    # (Some key/value stores return empty string instead of nil.)
    #
    def interpret(value)
      value == "" ? nil : value
    end

    def expire_single_url(url)
      store_service.remove(url)
    end
  end
end
