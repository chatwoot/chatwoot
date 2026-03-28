# frozen_string_literal: true

module Igaralead
  class LimitEnforcementService
    class << self
      # Returns { agents: Integer, inboxes: Integer } matching Account#usage_limits format.
      # Reads from the shared igaralead DB first, falls back to Hub API, then ChatwootApp.max_limit.
      def usage_limits(account)
        fallback = ChatwootApp.max_limit.to_i
        sub = subscription_for(account)

        if sub
          {
            agents: sub.nexus_user_limit.then { |v| v.positive? ? v : fallback },
            inboxes: sub.nexus_channel_limit.then { |v| v.positive? ? v : fallback }
          }
        else
          # Fallback: try Hub API for accounts not yet in shared DB
          settings = fetch_settings_from_hub(account)
          {
            agents: settings.dig('nexus', 'user_limit').to_i.then { |v| v.positive? ? v : fallback },
            inboxes: settings.dig('nexus', 'channel_limit').to_i.then { |v| v.positive? ? v : fallback }
          }
        end
      end

      private

      def subscription_for(account)
        hub_id = account.hub_id
        return nil if hub_id.blank?

        cache_key = "igaralead:sub:#{hub_id}"
        cached = Rails.cache.read(cache_key)
        return cached if cached

        org = Igaralead::SharedOrganization.find_by(id: hub_id)
        return nil unless org

        sub = org.shared_subscriptions.active.first
        Rails.cache.write(cache_key, sub, expires_in: 5.minutes) if sub
        sub
      rescue StandardError => e
        Rails.logger.warn("[Igaralead::LimitEnforcementService] Shared DB read failed: #{e.message}")
        nil
      end

      def fetch_settings_from_hub(account)
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
        Rails.logger.warn("[Igaralead::LimitEnforcementService] Hub API fetch failed: #{e.message}")
        {}
      end
    end
  end
end
