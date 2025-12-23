class Module
  include Minitest::Spec::DSL
end

module ControllerRoutesAfterBlock
  after do
    Rails.application.reload_routes!
  end
end

module CustomControllersRoutes
  include ControllerRoutesAfterBlock

  before do
    Rails.application.routes.draw do
      mount_devise_token_auth_for 'User', at: 'nice_user_auth', controllers: {
        registrations: 'custom/registrations',
        confirmations: 'custom/confirmations',
        passwords: 'custom/passwords',
        sessions: 'custom/sessions',
        token_validations: 'custom/token_validations',
        omniauth_callbacks: 'custom/omniauth_callbacks'
      }
    end
  end
end

module OverridesControllersRoutes
  include ControllerRoutesAfterBlock

  before do
    Rails.application.routes.draw do
      mount_devise_token_auth_for 'User', at: 'evil_user_auth', controllers: {
        confirmations:      'overrides/confirmations',
        passwords:          'overrides/passwords',
        omniauth_callbacks: 'overrides/omniauth_callbacks',
        registrations:      'overrides/registrations',
        sessions:           'overrides/sessions',
        token_validations:  'overrides/token_validations'
      }
    end
  end
end
