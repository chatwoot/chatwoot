# frozen_string_literal: true

module DeviseTokenAuth
  class ApplicationController < DeviseController
    include DeviseTokenAuth::Concerns::SetUserByToken

    def resource_data(opts = {})
      response_data = opts[:resource_json] || @resource.as_json
      response_data['type'] = @resource.class.name.parameterize if json_api?
      response_data
    end

    def resource_errors
      @resource.errors.to_hash.merge(full_messages: @resource.errors.full_messages)
    end

    protected

    def blacklisted_redirect_url?(redirect_url)
      DeviseTokenAuth.redirect_whitelist && !DeviseTokenAuth::Url.whitelisted?(redirect_url)
    end

    def build_redirect_headers(access_token, client, redirect_header_options = {})
      {
        DeviseTokenAuth.headers_names[:"access-token"] => access_token,
        DeviseTokenAuth.headers_names[:"client"] => client,
        :config => params[:config],

        # Legacy parameters which may be removed in a future release.
        # Consider using "client" and "access-token" in client code.
        # See: github.com/lynndylanhurley/devise_token_auth/issues/993
        :client_id => client,
        :token => access_token
      }.merge(redirect_header_options)
    end

    def params_for_resource(resource)
      devise_parameter_sanitizer.instance_values['permitted'][resource].each do |type|
        params[type.to_s] ||= request.headers[type.to_s] unless request.headers[type.to_s].nil?
      end
      devise_parameter_sanitizer.instance_values['permitted'][resource]
    end

    def resource_class(m = nil)
      if m
        mapping = Devise.mappings[m]
      else
        mapping = Devise.mappings[resource_name] || Devise.mappings.values.first
      end

      mapping.to
    end

    def json_api?
      return false unless defined?(ActiveModel::Serializer)
      return ActiveModel::Serializer.setup do |config|
        config.adapter == :json_api
      end if ActiveModel::Serializer.respond_to?(:setup)
      ActiveModelSerializers.config.adapter == :json_api
    end

    def recoverable_enabled?
      resource_class.devise_modules.include?(:recoverable)
    end

    def confirmable_enabled?
      resource_class.devise_modules.include?(:confirmable)
    end

    def render_error(status, message, data = nil)
      response = {
        success: false,
        errors: [message]
      }
      response = response.merge(data) if data
      render json: response, status: status
    end

    def success_message(name, email)
      if Devise.paranoid
        I18n.t("devise_token_auth.#{name}.sended_paranoid")
      else
        I18n.t("devise_token_auth.#{name}.sended", email: email)
      end
    end

    def redirect_options
      {}
    end

    # When using a cookie to transport the auth token we can set it immediately in flows such as
    # reset password and OmniAuth success, rather than making the client scrape the token from
    # query params (to then send in the initial validate_token request).
    # TODO: We should be able to stop exposing the token in query params when this method is used
    def set_token_in_cookie(resource, token)
      auth_header = resource.build_auth_headers(token.token, token.client)
      cookies[DeviseTokenAuth.cookie_name] = DeviseTokenAuth.cookie_attributes.merge(value: auth_header.to_json)
    end
  end
end
