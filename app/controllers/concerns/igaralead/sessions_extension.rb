module Igaralead
  module SessionsExtension
    extend ActiveSupport::Concern

    private

    def find_user_for_authentication
      # When Hub OAuth is the sole login method, only SSO-token logins are
      # allowed (the token comes from the OAuth callback redirect).
      # Direct email/password attempts are rejected.
      if hub_sso_only? && params[:sso_auth_token].blank?
        return nil
      end

      user = super
      return nil unless user

      verify_hub_access(user) ? user : nil
    end

    def hub_sso_only?
      ENV['HUB_OAUTH_CLIENT_ID'].present?
    end

    def verify_hub_access(user)
      return true unless Igaralead::HubClient.configured?

      account = user.accounts.find_by(hub_client_slug: hub_client_slug_from_request)
      return true unless account

      slug = account.hub_client_slug
      return true if slug.blank?

      cache_key = "igaralead:access:#{slug}:nexus"
      cached = Rails.cache.read(cache_key)
      return cached unless cached.nil?

      active = check_hub_subscription(slug)
      Rails.cache.write(cache_key, active, expires_in: 5.minutes)
      active
    rescue Faraday::Error => e
      Rails.logger.warn("[Igaralead] Hub access check failed, allowing: #{e.message}")
      true
    end

    def check_hub_subscription(slug)
      client = Igaralead::HubClient.new
      response = client.get("/c/#{slug}/subscription")
      return true unless response.is_a?(Hash)

      allocations = response['allocations'] || {}
      allocations['nexus_users'].to_i.positive?
    end

    def hub_client_slug_from_request
      # Extract from referrer URL or request params
      params[:client_slug] || extract_slug_from_referrer
    end

    def extract_slug_from_referrer
      return nil if request.referrer.blank?

      match = request.referrer.match(%r{/c/([^/]+)})
      match&.captures&.first
    end
  end
end
