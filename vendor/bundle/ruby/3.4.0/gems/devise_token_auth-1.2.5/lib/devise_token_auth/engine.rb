# frozen_string_literal: true

require 'devise_token_auth/rails/routes'

module DeviseTokenAuth
  class Engine < ::Rails::Engine
    isolate_namespace DeviseTokenAuth

    initializer 'devise_token_auth.url_helpers' do
      Devise.helpers << DeviseTokenAuth::Controllers::Helpers
    end
  end

  mattr_accessor :change_headers_on_each_request,
                 :max_number_of_devices,
                 :token_lifespan,
                 :token_cost,
                 :batch_request_buffer_throttle,
                 :omniauth_prefix,
                 :default_confirm_success_url,
                 :default_password_reset_url,
                 :redirect_whitelist,
                 :check_current_password_before_update,
                 :enable_standard_devise_support,
                 :remove_tokens_after_password_reset,
                 :default_callbacks,
                 :headers_names,
                 :cookie_enabled,
                 :cookie_name,
                 :cookie_attributes,
                 :bypass_sign_in,
                 :send_confirmation_email,
                 :require_client_password_reset_token,
                 :other_uid

  self.change_headers_on_each_request       = true
  self.max_number_of_devices                = 10
  self.token_lifespan                       = 2.weeks
  self.token_cost                           = 10
  self.batch_request_buffer_throttle        = 5.seconds
  self.omniauth_prefix                      = '/omniauth'
  self.default_confirm_success_url          = nil
  self.default_password_reset_url           = nil
  self.redirect_whitelist                   = nil
  self.check_current_password_before_update = false
  self.enable_standard_devise_support       = false
  self.remove_tokens_after_password_reset   = false
  self.default_callbacks                    = true
  self.headers_names                        = { 'authorization': 'Authorization',
                                                'access-token': 'access-token',
                                                'client': 'client',
                                                'expiry': 'expiry',
                                                'uid': 'uid',
                                                'token-type': 'token-type' }
  self.cookie_enabled                       = false
  self.cookie_name                          = 'auth_cookie'
  self.cookie_attributes                    = {}
  self.bypass_sign_in                       = true
  self.send_confirmation_email              = false
  self.require_client_password_reset_token  = false
  self.other_uid                            = nil

  def self.setup(&block)
    yield self

    Rails.application.config.after_initialize do
      if defined?(::OmniAuth)
        ::OmniAuth::config.path_prefix = Devise.omniauth_path_prefix = omniauth_prefix

        # Omniauth currently does not pass along omniauth.params upon failure redirect
        # see also: https://github.com/intridea/omniauth/issues/626
        OmniAuth::FailureEndpoint.class_eval do
          def redirect_to_failure
            message_key = env['omniauth.error.type']
            origin_query_param = env['omniauth.origin'] ? "&origin=#{CGI.escape(env['omniauth.origin'])}" : ''
            strategy_name_query_param = env['omniauth.error.strategy'] ? "&strategy=#{env['omniauth.error.strategy'].name}" : ''
            extra_params = env['omniauth.params'] ? "&#{env['omniauth.params'].to_query}" : ''
            new_path = "#{env['SCRIPT_NAME']}#{OmniAuth.config.path_prefix}/failure?message=#{message_key}#{origin_query_param}#{strategy_name_query_param}#{extra_params}"
            Rack::Response.new(['302 Moved'], 302, 'Location' => new_path).finish
          end
        end

        # Omniauth currently removes omniauth.params during mocked requests
        # see also: https://github.com/intridea/omniauth/pull/812
        OmniAuth::Strategy.class_eval do
          def mock_callback_call
            setup_phase
            @env['omniauth.origin'] = session.delete('omniauth.origin')
            @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
            @env['omniauth.params'] = session.delete('omniauth.params') || {}
            mocked_auth = OmniAuth.mock_auth_for(name.to_s)
            if mocked_auth.is_a?(Symbol)
              fail!(mocked_auth)
            else
              @env['omniauth.auth'] = mocked_auth
              OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
              call_app!
            end
          end
        end

      end
    end
  end
end
