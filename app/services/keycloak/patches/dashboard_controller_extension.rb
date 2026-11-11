module Keycloak::Patches::DashboardControllerExtension
  private

  def allowed_login_methods
    methods = super
    methods += ['keycloak'] if ENV['KEYCLOAK_ISSUER'].present? && methods.exclude?('keycloak')
    methods
  end
end
