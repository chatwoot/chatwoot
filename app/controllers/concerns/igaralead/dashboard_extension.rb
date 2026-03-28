# frozen_string_literal: true

module Igaralead::DashboardExtension
  extend ActiveSupport::Concern

  private

  # When Hub OAuth is configured, expose Hub SSO as the primary login method
  # plus social logins (Google/Facebook) routed through Hub, and email/password.
  def allowed_login_methods
    return ['igarahub', 'google_oauth', 'facebook_oauth', 'email'] if ENV['HUB_OAUTH_CLIENT_ID'].present?

    super
  end
end
