# frozen_string_literal: true

module DeviseTokenAuth
  class ConfirmationsController < DeviseTokenAuth::ApplicationController

    def show
      @resource = resource_class.confirm_by_token(resource_params[:confirmation_token])

      if @resource.errors.empty?
        yield @resource if block_given?

        redirect_header_options = { account_confirmation_success: true }

        if signed_in?(resource_name)
          token = signed_in_resource.create_token
          signed_in_resource.save!

          redirect_headers = build_redirect_headers(token.token,
                                                    token.client,
                                                    redirect_header_options)

          redirect_to_link = signed_in_resource.build_auth_url(redirect_url, redirect_headers)
        else
          redirect_to_link = DeviseTokenAuth::Url.generate(redirect_url, redirect_header_options)
        end

        redirect_to(redirect_to_link, redirect_options)
      else
        if redirect_url
          redirect_to DeviseTokenAuth::Url.generate(redirect_url, account_confirmation_success: false), redirect_options
        else
          raise ActionController::RoutingError, 'Not Found'
        end
      end
    end

    def create
      return render_create_error_missing_email if resource_params[:email].blank?

      @email = get_case_insensitive_field_from_resource_params(:email)

      @resource = resource_class.dta_find_by(uid: @email, provider: provider)

      return render_not_found_error unless @resource

      @resource.send_confirmation_instructions({
        redirect_url: redirect_url,
        client_config: resource_params[:config_name]
      })

      return render_create_success
    end

    protected

    def render_create_error_missing_email
      render_error(401, I18n.t('devise_token_auth.confirmations.missing_email'))
    end

    def render_create_success
      render json: {
               success: true,
               message: success_message('confirmations', @email)
             }
    end

    def render_not_found_error
      if Devise.paranoid
        render_create_success
      else
        render_error(404, I18n.t('devise_token_auth.confirmations.user_not_found', email: @email))
      end
    end

    private

    def resource_params
      params.permit(:email, :confirmation_token, :config_name)
    end

    # give redirect value from params priority or fall back to default value if provided
    def redirect_url
      params.fetch(
        :redirect_url,
        DeviseTokenAuth.default_confirm_success_url
      )
    end
  end
end
