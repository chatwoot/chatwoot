require 'geocoder/cache_stores/base'

module Geocoder::CacheStore
  class Redis < Base
    def initialize(store, options)
      super
      @expiration = options[:expiration]
    end

    def write(url, value, expire = @expiration)
      if expire.present?
        store.set key_for(url), value, ex: expire
      else
        store.set key_for(url), value
      end
    end

    def read(url)
      store.get key_for(url)
    end

    def keys
      store.keys("#{prefix}*")
    end

    def remove(key)
      store.del(key)
    end

    private # ----------------------------------------------------------------

    def expire; @expiration; end
  end
end
