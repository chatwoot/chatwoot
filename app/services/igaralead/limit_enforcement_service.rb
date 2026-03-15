# frozen_string_literal: true

module Igaralead
  class LimitEnforcementService
    class << self
      # Returns { agents: Integer, inboxes: Integer } matching Account#usage_limits format.
      # Falls back to ChatwootApp.max_limit when Hub is unreachable.
      def usage_limits(account)
        settings = fetch_settings(account)
        fallback = ChatwootApp.max_limit.to_i

        {
          agents: settings.dig('nexus', 'user_limit').to_i.then { |v| v.positive? ? v : fallback },
          inboxes: settings.dig('nexus', 'channel_limit').to_i.then { |v| v.positive? ? v : fallback }
        }
      end

      private

      def fetch_settings(account)
        slug = account.hub_client_slug
        return {} if slug.blank? || !HubClient.configured?

        cache_key = "igaralead:limits:#{slug}"
        cached = Rails.cache.read(cache_key)
        return cached if cached.present?

        client = HubClient.new
        response = client.get("/c/#{slug}/settings")
        return {} unless response.is_a?(Hash)

        Rails.cache.write(cache_key, response, expires_in: 5.minutes)
        response
      rescue Faraday::Error => e
        Rails.logger.warn("[Igaralead::LimitEnforcementService] Settings fetch failed: #{e.message}")
        {}
      end
    end
  end
end
