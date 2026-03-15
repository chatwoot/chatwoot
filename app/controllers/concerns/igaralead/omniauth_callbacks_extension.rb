module Igaralead
  module OmniauthCallbacksExtension
    extend ActiveSupport::Concern

    def omniauth_success
      if auth_hash['provider'] == 'igarahub'
        handle_hub_callback
      else
        super
      end
    end

    private

    def handle_hub_callback
      info = auth_hash['info']
      email = info['email']
      client_slug = info['client_slug']
      hub_user_id = auth_hash['uid']

      account = Account.find_by(hub_client_slug: client_slug)
      return redirect_to login_page_url(error: 'no-account-found') unless account

      unless hub_product_active?(account)
        return redirect_to login_page_url(error: 'product-not-active')
      end

      @resource = find_or_create_hub_user(email, hub_user_id, info, account)
      sign_in_user
    end

    def find_or_create_hub_user(email, hub_user_id, info, account)
      user = User.find_by(hub_id: hub_user_id) || User.from_email(email)

      if user
        user.update(hub_id: hub_user_id, hub_synced_at: Time.current, name: info['name']) if user.hub_id.blank?
        ensure_account_user(user, account, info['roles'])
        user
      else
        create_hub_user(email, hub_user_id, info, account)
      end
    end

    def create_hub_user(email, hub_user_id, info, account)
      user = User.new(
        email: email,
        name: info['name'],
        hub_id: hub_user_id,
        hub_synced_at: Time.current,
        password: SecureRandom.alphanumeric(24),
        confirmed_at: Time.current
      )
      user.skip_confirmation!
      user.save!
      ensure_account_user(user, account, info['roles'])
      user
    end

    def ensure_account_user(user, account, hub_roles)
      account_user = AccountUser.find_by(user: user, account: account)
      return account_user if account_user

      role = hub_roles&.include?('admin') ? :administrator : :agent
      AccountUser.create!(user: user, account: account, role: role)
    end

    def hub_product_active?(account)
      return true unless Igaralead::HubClient.configured?

      client = Igaralead::HubClient.new
      slug = account.hub_client_slug
      return true if slug.blank?

      response = client.get("/c/#{slug}/subscription")
      return true unless response.is_a?(Hash)
      return false unless response['active']

      products = response['products'] || {}
      products['nexus'].present?
    rescue Faraday::Error => e
      Rails.logger.warn("[Igaralead] Hub product check failed, allowing access: #{e.message}")
      true
    end
  end
end
