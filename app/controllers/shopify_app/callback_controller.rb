# frozen_string_literal: true

module ShopifyApp
  # Performs login after OAuth completes
  class CallbackController < ActionController::Base
    include ShopifyApp::LoginProtection
    include ShopifyApp::EnsureBilling
    include Shopify::IntegrationHelper

    def callback
      Rails.logger.info("Got Shopify callback");
      begin
        api_session, cookie = validated_auth_objects
      rescue => error
        if error.class.module_parent == ShopifyAPI::Errors
          callback_rescue(error)
          return respond_with_error
        else
          raise error
        end
      end

      save_session(api_session) if api_session
      update_rails_cookie(api_session, cookie)

      return respond_with_user_token_flow if start_user_token_flow?(api_session)

      Rails.logger.info("Params #{params} #{api_session}")

      account_id = verify_shopify_token(params[:state])
      account ||= Account.find(account_id)

      account.hooks.create!(
        app_id: 'shopify',
        access_token: api_session.access_token,
        status: 'enabled',
        reference_id: api_session.shop,
        settings: {
          scope: api_session.scope
        }
      )

      if ShopifyApp::VERSION < "23.0"
        # deprecated in 23.0
        if ShopifyApp.configuration.custom_post_authenticate_tasks.present?
          ShopifyApp.configuration.post_authenticate_tasks.perform(api_session)
        else
          perform_post_authenticate_jobs(api_session)
        end
      else
        ShopifyApp.configuration.post_authenticate_tasks.perform(api_session)
      end
      redirect_to_app if check_billing(api_session)
    end

    private

    def callback_rescue(error)
      ShopifyApp::Logger.debug("#{error.class} was rescued and redirected to login_url_with_optional_shop")
    end

    def deprecate_callback_rescue(error)
      message = <<~EOS
        An error of type #{error.class} was rescued. This is not part of `ShopifyAPI::Errors`, which could indicate a
        bug in your app, or a bug in the shopify_app gem. Future versions of the gem may re-raise this error rather
        than rescuing it.
      EOS
      ShopifyApp::Logger.deprecated(message, "22.0.0")
    end

    def save_session(api_session)
      ShopifyApp::SessionRepository.store_session(api_session)
    end

    def validated_auth_objects
      filtered_params = request.parameters.symbolize_keys.slice(:code, :shop, :timestamp, :state, :host, :hmac)

      oauth_payload = ShopifyAPI::Auth::Oauth.validate_auth_callback(
        cookies: {
          ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME =>
            cookies.encrypted[ShopifyAPI::Auth::Oauth::SessionCookie::SESSION_COOKIE_NAME],
        },
        auth_query: ShopifyAPI::Auth::Oauth::AuthQuery.new(**filtered_params),
      )
      api_session = oauth_payload.dig(:session)
      cookie = oauth_payload.dig(:cookie)

      [api_session, cookie]
    end

    def update_rails_cookie(api_session, cookie)
      if cookie.value.present?
        cookies.encrypted[cookie.name] = {
          expires: cookie.expires,
          secure: true,
          http_only: true,
          value: cookie.value,
        }
      end

      session[:shopify_user_id] = api_session.associated_user.id if api_session.online?
      ShopifyApp::Logger.debug("Saving Shopify user ID to cookie")
    end

    def redirect_to_app
      if ShopifyAPI::Context.embedded?
        return_to = session.delete(:return_to)
        redirect_to = if fully_formed_url?(return_to)
          return_to
        else
          "#{decoded_host}#{return_to}"
        end

        redirect_to = ShopifyApp.configuration.root_url if deduced_phishing_attack?
        redirect_to(redirect_to, allow_other_host: true)
      else
        redirect_to(return_address)
      end
    end

    def fully_formed_url?(return_to)
      uri = Addressable::URI.parse(return_to)
      uri.present? && uri.scheme.present? && uri.host.present?
    end

    def decoded_host
      @decoded_host ||= ShopifyAPI::Auth.embedded_app_url(params[:host])
    end

    # host param doesn't match the configured myshopify_domain
    def deduced_phishing_attack?
      sanitized_host = ShopifyApp::Utils.sanitize_shop_domain(URI(decoded_host).host)
      if sanitized_host.nil?
        ShopifyApp::Logger.info("host param from callback is not from a trusted domain")
        ShopifyApp::Logger.info("redirecting to root as this is likely a phishing attack")
      end
      sanitized_host.nil?
    end

    def respond_with_error
      flash[:error] = I18n.t("could_not_log_in")
      redirect_to(login_url_with_optional_shop)
    end

    def respond_with_user_token_flow
      redirect_to(login_url_with_optional_shop)
    end

    def start_user_token_flow?(shopify_session)
      return false unless ShopifyApp::SessionRepository.user_storage.present?
      return false if shopify_session.online?

      update_user_access_scopes?
    end

    def update_user_access_scopes?
      return true if session[:shopify_user_id].nil?

      user_access_scopes_strategy.update_access_scopes?(shopify_user_id: session[:shopify_user_id])
    end

    def user_access_scopes_strategy
      ShopifyApp.configuration.user_access_scopes_strategy
    end

    def perform_post_authenticate_jobs(session)
      # Ensure we use the shop session to install webhooks
      session_for_shop = session.online? ? shop_session : session

      install_webhooks(session_for_shop)

      perform_after_authenticate_job(session)
    end

    def install_webhooks(session)
      return unless ShopifyApp.configuration.has_webhooks?

      WebhooksManager.queue(session.shop, session.access_token)
    end

    def perform_after_authenticate_job(session)
      config = ShopifyApp.configuration.after_authenticate_job

      return unless config && config[:job].present?

      job = config[:job]
      job = job.constantize if job.is_a?(String)

      if config[:inline] == true
        job.perform_now(shop_domain: session.shop)
      else
        job.perform_later(shop_domain: session.shop)
      end
    end
  end
end
