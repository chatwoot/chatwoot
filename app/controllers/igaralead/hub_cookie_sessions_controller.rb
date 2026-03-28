# frozen_string_literal: true

# Handles automatic SSO via the shared `hub_access` cookie.
#
# When a user is already logged in at Hub (hub.igaralead.com.br) and navigates
# to Nexus, the `hub_access` JWT is available as an httpOnly cookie on the
# shared parent domain (.igaralead.com.br). This controller validates that JWT
# locally (no Hub round-trip) and creates a Nexus session, redirecting the
# user into the app without requiring them to click "Sign in with Hub".
#
# Flow:
#   GET /igaralead/sso  (linked from Hub's product switcher)
#     → validate hub_access cookie JWT via JWKS
#     → find/create User + AccountUser
#     → generate sso_auth_token → redirect to frontend login page
#
# The frontend then calls POST /auth/sign_in with the sso_auth_token as usual.

module Igaralead
  class HubCookieSessionsController < ApplicationController
    skip_before_action :authenticate_user!, raise: false

    # GET /igaralead/sso
    def create
      token = cookies[:hub_access]
      if token.blank?
        redirect_to login_page_url(error: 'no-hub-session') and return
      end

      payload = Igaralead::HubTokenValidator.validate(token)
      if payload.nil?
        redirect_to login_page_url(error: 'invalid-hub-token') and return
      end

      hub_user_id = payload['user_id']&.to_s
      email = payload['email']
      name = payload['name']
      roles = payload['roles'] || []
      memberships = payload['memberships'] || []

      # Determine account from memberships that have nexus active
      nexus_membership = memberships.find { |m| m.dig('active_products', 'nexus') }
      client_slug = nexus_membership&.dig('slug') || payload['client_slug']

      account = client_slug.present? ? Account.find_by(hub_client_slug: client_slug) : nil

      unless account
        Rails.logger.warn("[Igaralead::HubCookieSSO] No account for slug=#{client_slug} user=#{email}")
        redirect_to login_page_url(error: 'no-account-found') and return
      end

      # Super admins bypass the nexus-active check
      is_super_admin = roles.include?('super_admin')
      unless is_super_admin || nexus_membership.present?
        redirect_to login_page_url(error: 'product-not-active') and return
      end

      user = find_or_create_user(hub_user_id, email, name, roles, account)
      unless user
        redirect_to login_page_url(error: 'user-creation-failed') and return
      end

      sso_token = user.generate_sso_auth_token
      redirect_to login_page_url(
        email: user.email,
        sso_auth_token: sso_token,
        account_id: account.id
      )
    end

    private

    def find_or_create_user(hub_user_id, email, name, roles, account)
      user = hub_user_id.present? ? User.find_by(hub_id: hub_user_id) : nil
      user ||= User.from_email(email) if email.present?

      if user
        user.update_columns(hub_id: hub_user_id, hub_synced_at: Time.current) if user.hub_id.blank?
        ensure_account_user(user, account, roles)
      else
        return nil if email.blank?

        user = User.new(
          email: email,
          name: name.presence || email.split('@').first,
          hub_id: hub_user_id,
          hub_synced_at: Time.current,
          password: SecureRandom.alphanumeric(24),
          confirmed_at: Time.current
        )
        user.skip_confirmation!
        user.save!
        ensure_account_user(user, account, roles)
      end

      user
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Igaralead::HubCookieSSO] User creation failed: #{e.message}")
      nil
    end

    def ensure_account_user(user, account, hub_roles)
      account_user = AccountUser.find_by(user: user, account: account)
      return account_user if account_user

      role = (hub_roles.include?('admin') || hub_roles.include?('super_admin')) ? :administrator : :agent
      AccountUser.create!(user: user, account: account, role: role)
    end

    def login_page_url(**params)
      frontend_url = ENV.fetch('FRONTEND_URL', '')
      query = params.any? ? "?#{params.to_query}" : ''
      "#{frontend_url}/app/login#{query}"
    end
  end
end
