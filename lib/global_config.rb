class GlobalConfig
  VERSION = 'V1'.freeze
  KEY_PREFIX = 'GLOBAL_CONFIG'.freeze
  DEFAULT_EXPIRY = 1.day

  class << self
    def get(*args)
      config_keys = *args
      config = {}

      config_keys.each do |config_key|
        config[config_key] = load_from_cache(config_key)
      end

      config.with_indifferent_access
    end

    def get_value(arg)
      load_from_cache(arg)
    end

    def clear_cache
      cached_keys = $alfred.keys("#{VERSION}:#{KEY_PREFIX}:*")
      (cached_keys || []).each do |cached_key|
        $alfred.expire(cached_key, 0)
      end
    end

    private

    def load_from_cache(config_key)
      cache_key = "#{VERSION}:#{KEY_PREFIX}:#{config_key}"
      cached_value = $alfred.get(cache_key)

      if cached_value.blank?
        value_from_db = db_fallback(config_key)
        cached_value = { value: value_from_db }.to_json
        $alfred.set(cache_key, cached_value, { ex: DEFAULT_EXPIRY })
      end

      JSON.parse(cached_value)['value']
    end

    def db_fallback(config_key)
      InstallationConfig.find_by(name: config_key)&.value
    end
  end
end
