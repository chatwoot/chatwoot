module Geocoder::CacheStore
  class Base
    def initialize(store, options)
      @store = store
      @config = options
      @prefix = config[:prefix]
    end

    ##
    # Array of keys with the currently configured prefix
    # that have non-nil values.
    def keys
      store.keys.select { |k| k.match(/^#{prefix}/) and self[k] }
    end

    ##
    # Array of cached URLs.
    #
    def urls
      keys
    end

    protected # ----------------------------------------------------------------

    def prefix; @prefix; end
    def store; @store; end
    def config; @config; end

    ##
    # Cache key for a given URL.
    #
    def key_for(url)
      if url.match(/^#{prefix}/)
        url
      else
        [prefix, url].join
      end
    end
  end
end