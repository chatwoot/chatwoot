# frozen_string_literal: true

module DeviseTokenAuth
  class PasswordsController < DeviseTokenAuth::ApplicationController
    before_action :validate_redirect_url_param, only: [:create, :edit]
    skip_after_action :update_auth_header, only: [:create, :edit]

    # this action is responsible for generating password reset tokens and sending emails
    def create
      return render_create_error_missing_email unless resource_params[:email]

      @email = get_case_insensitive_field_from_resource_params(:email)
      @resource = find_resource(:uid, @email)

      if @resource
        yield @resource if block_given?
        @resource.send_reset_password_instructions(
          email: @email,
          provider: 'email',
          redirect_url: @redirect_url,
          client_config: params[:config_name]
        )

        if @resource.errors.empty?
          return render_create_success
        else
          render_create_error @resource.errors
        end
      else
        render_not_found_error
      end
    end

    # this is where users arrive after visiting the password reset confirmation link
    def edit
      # if a user is not found, return nil
      @resource = resource_class.with_reset_password_token(resource_params[:reset_password_token])

      if @resource && @resource.reset_password_period_valid?
        token = @resource.create_token unless require_client_password_reset_token?

        # ensure that user is confirmed
        @resource.skip_confirmation! if confirmable_enabled? && !@resource.confirmed_at
        # allow user to change password once without current_password
        @resource.allow_password_change = true if recoverable_enabled?

        @resource.save!

        yield @resource if block_given?

        if require_client_password_reset_token?
          redirect_to DeviseTokenAuth::Url.generate(@redirect_url, reset_password_token: resource_params[:reset_password_token]),
          redirect_options
        else
          if DeviseTokenAuth.cookie_enabled
            set_token_in_cookie(@resource, token)
          end

          redirect_header_options = { reset_password: true }
          redirect_headers = build_redirect_headers(token.token,
                                                    token.client,
                                                    redirect_header_options)
          redirect_to(@resource.build_auth_url(@redirect_url,
                                               redirect_headers),
                                               redirect_options)
        end
      else
        render_edit_error
      end
    end

    def update
      # make sure user is authorized
      if require_client_password_reset_token? && resource_params[:reset_password_token]
        @resource = resource_class.with_reset_password_token(resource_params[:reset_password_token])
        return render_update_error_unauthorized unless @resource

        @token = @resource.create_token
      else
        @resource = set_user_by_token
      end

      return render_update_error_unauthorized unless @resource

      # make sure account doesn't use oauth2 provider
      unless @resource.provider == 'email'
        return render_update_error_password_not_required
      end

      # ensure that password params were sent
      unless password_resource_params[:password] && password_resource_params[:password_confirmation]
        return render_update_error_missing_password
      end

      if @resource.send(resource_update_method, password_resource_params)
        @resource.allow_password_change = false if recoverable_enabled?
        @resource.save!

        yield @resource if block_given?
        return render_update_success
      else
        return render_update_error
      end
    end

    protected

    def resource_update_method
      allow_password_change = recoverable_enabled? && @resource.allow_password_change == true || require_client_password_reset_token?
      if DeviseTokenAuth.check_current_password_before_update == false || allow_password_change
        'update'
      else
        'update_with_password'
      end
    end

    def render_create_error_missing_email
      render_error(401, I18n.t('devise_token_auth.passwords.missing_email'))
    end

    def render_create_error_missing_redirect_url
      render_error(401, I18n.t('devise_token_auth.passwords.missing_redirect_url'))
    end

    def render_error_not_allowed_redirect_url
      response = {
        status: 'error',
        data:   resource_data
      }
      message = I18n.t('devise_token_auth.passwords.not_allowed_redirect_url', redirect_url: @redirect_url)
      render_error(422, message, response)
    end

    def render_create_success
      render json: {
        success: true,
        message: success_message('passwords', @email)
      }
    end

    def render_create_error(errors)
      render json: {
        success: false,
        errors: errors
      }, status: 400
    end

    def render_edit_error
      raise ActionController::RoutingError, 'Not Found'
    end

    def render_update_error_unauthorized
      render_error(401, 'Unauthorized')
    end

    def render_update_error_password_not_required
      render_error(422, I18n.t('devise_token_auth.passwords.password_not_required', provider: @resource.provider.humanize))
    end

    def render_update_error_missing_password
      render_error(422, I18n.t('devise_token_auth.passwords.missing_passwords'))
    end

    def render_update_success
      render json: {
        success: true,
        data: resource_data,
        message: I18n.t('devise_token_auth.passwords.successfully_updated')
      }
    end

    def render_update_error
      render json: {
        success: false,
        errors: resource_errors
      }, status: 422
    end

    private

    def resource_params
      params.permit(:email, :reset_password_token)
    end

    def password_resource_params
      params.permit(*params_for_resource(:account_update))
    end

    def render_not_found_error
      if Devise.paranoid
        render_create_success
      else
        render_error(404, I18n.t('devise_token_auth.passwords.user_not_found', email: @email))
      end
    end

    def validate_redirect_url_param
      # give redirect value from params priority
      @redirect_url = params.fetch(
        :redirect_url,
        DeviseTokenAuth.default_password_reset_url
      )

      return render_create_error_missing_redirect_url unless @redirect_url
      return render_error_not_allowed_redirect_url if blacklisted_redirect_url?(@redirect_url)
    end

    def reset_password_token_as_raw?(recoverable)
      recoverable && recoverable.reset_password_token.present? && !require_client_password_reset_token?
    end

    def require_client_password_reset_token?
      DeviseTokenAuth.require_client_password_reset_token
    end
  end
end
