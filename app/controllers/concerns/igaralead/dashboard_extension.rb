# frozen_string_literal: true

module Igaralead::DashboardExtension
  extend ActiveSupport::Concern

  private

  # Hub login is now direct (shared DB), so expose email/password
  # plus social logins (Google/Facebook) as available methods.
  def allowed_login_methods
    ['email', 'google_oauth', 'facebook_oauth']
  end
end
