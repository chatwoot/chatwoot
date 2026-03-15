# frozen_string_literal: true

module Igaralead::DashboardExtension
  extend ActiveSupport::Concern

  private

  # When Hub OAuth is configured, disable email/password login and only expose
  # the Hub SSO provider.  This keeps the change merge-safe — the original
  # method lives in the upstream controller and is left untouched.
  def allowed_login_methods
    return ['igarahub'] if ENV['HUB_OAUTH_CLIENT_ID'].present?

    super
  end
end
