module Igaralead
  class HubSettingsService
    CACHE_TTL = 10.minutes
    CACHE_PREFIX = 'igaralead:settings'.freeze

    class << self
      def for_account(account)
        new(account).settings
      end

      def clear_cache(account)
        slug = account.hub_client_slug
        return if slug.blank?

        Rails.cache.delete("#{CACHE_PREFIX}:#{slug}")
      end
    end

    def initialize(account)
      @account = account
      @slug = account.hub_client_slug
    end

    def settings
      return {} if @slug.blank? || !HubClient.configured?

      cached_settings || fetch_and_cache
    end

    def get(key, default = nil)
      settings.fetch(key.to_s, default)
    end

    private

    def cache_key
      "#{CACHE_PREFIX}:#{@slug}"
    end

    def cached_settings
      Rails.cache.read(cache_key)
    end

    def fetch_and_cache
      remote = fetch_from_hub
      Rails.cache.write(cache_key, remote, expires_in: CACHE_TTL)
      remote
    rescue Faraday::Error => e
      Rails.logger.warn("[Igaralead::HubSettingsService] Failed to fetch settings: #{e.message}")
      stale = Rails.cache.read(cache_key)
      stale || {}
    end

    def fetch_from_hub
      client = HubClient.new
      response = client.get("/c/#{@slug}/settings")
      return {} unless response.is_a?(Hash)

      normalize_settings(response)
    end

    def normalize_settings(raw)
      {
        'nexus_user_limit' => raw.dig('nexus', 'user_limit'),
        'nexus_channel_limit' => raw.dig('nexus', 'channel_limit'),
        'nexus_features' => raw.dig('nexus', 'features') || {},
        'organization_name' => raw['organization_name'],
        'organization_config' => raw['config'] || {}
      }.compact
    end
  end
end
