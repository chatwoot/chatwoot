# frozen_string_literal: true

module ActionDispatch::Routing
  class Mapper
    def mount_devise_token_auth_for(resource, opts)
      # ensure objects exist to simplify attr checks
      opts[:controllers] ||= {}
      opts[:skip]        ||= []

      # check for ctrl overrides, fall back to defaults
      sessions_ctrl          = opts[:controllers].delete(:sessions) || 'devise_token_auth/sessions'
      registrations_ctrl     = opts[:controllers].delete(:registrations) || 'devise_token_auth/registrations'
      passwords_ctrl         = opts[:controllers].delete(:passwords) || 'devise_token_auth/passwords'
      confirmations_ctrl     = opts[:controllers].delete(:confirmations) || 'devise_token_auth/confirmations'
      token_validations_ctrl = opts[:controllers].delete(:token_validations) || 'devise_token_auth/token_validations'
      omniauth_ctrl          = opts[:controllers].delete(:omniauth_callbacks) || 'devise_token_auth/omniauth_callbacks'
      unlocks_ctrl           = opts[:controllers].delete(:unlocks) || 'devise_token_auth/unlocks'

      # check for resource override
      route                  = opts[:as] || resource.pluralize.underscore.gsub('/', '_')

      # define devise controller mappings
      controllers = opts[:controllers].merge(
                      sessions: sessions_ctrl,
                      registrations: registrations_ctrl,
                      passwords: passwords_ctrl,
                      confirmations: confirmations_ctrl
                    )

      controllers[:unlocks] = unlocks_ctrl if unlocks_ctrl

      # remove any unwanted devise modules
      opts[:skip].each{ |item| controllers.delete(item) }

      devise_for route.to_sym,
                 class_name: resource,
                 module: :devise,
                 path: opts[:at].to_s,
                 controllers: controllers,
                 skip: opts[:skip] + [:omniauth_callbacks]

      unnest_namespace do
        # get full url path as if it were namespaced
        full_path = "#{@scope[:path]}/#{opts[:at]}"

        # get namespace name
        namespace_name = @scope[:as]

        # clear scope so controller routes aren't namespaced
        @scope = ActionDispatch::Routing::Mapper::Scope.new(
          path:         '',
          shallow_path: '',
          constraints:  {},
          defaults:     {},
          options:      {},
          parent:       nil
        )

        mapping_name = resource.underscore.gsub('/', '_')
        mapping_name = "#{namespace_name}_#{mapping_name}" if namespace_name

        devise_scope mapping_name.to_sym do
          # path to verify token validity
          get "#{full_path}/validate_token", controller: token_validations_ctrl.to_s, action: 'validate_token' if !opts[:skip].include?(:token_validations)

          # omniauth routes. only define if omniauth is installed and not skipped.
          if defined?(::OmniAuth) && !opts[:skip].include?(:omniauth_callbacks)
            match "#{full_path}/failure",             controller: omniauth_ctrl, action: 'omniauth_failure', via: [:get, :post]
            match "#{full_path}/:provider/callback",  controller: omniauth_ctrl, action: 'omniauth_success', via: [:get, :post]

            match "#{DeviseTokenAuth.omniauth_prefix}/:provider/callback", controller: omniauth_ctrl, action: 'redirect_callbacks', via: [:get, :post]
            match "#{DeviseTokenAuth.omniauth_prefix}/failure", controller: omniauth_ctrl, action: 'omniauth_failure', via: [:get, :post]

            # preserve the resource class thru oauth authentication by setting name of
            # resource as "resource_class" param
            match "#{full_path}/:provider", to: redirect(status: 307) { |params, request|
              # get the current querystring
              # TODO: deprecate in favor of using params
              qs = CGI::parse(request.env['QUERY_STRING'].empty? ? request.body.read : request.env['QUERY_STRING'] )

              # append name of current resource
              qs['resource_class'] = [resource]
              qs['namespace_name'] = [namespace_name] if namespace_name

              set_omniauth_path_prefix!(DeviseTokenAuth.omniauth_prefix)

              redirect_params = {}.tap { |hash| qs.each{ |k, v| hash[k] = v.first } }

              if DeviseTokenAuth.redirect_whitelist
                redirect_url = request.params['auth_origin_url']
                unless DeviseTokenAuth::Url.whitelisted?(redirect_url)
                  message = I18n.t(
                    'devise_token_auth.registrations.redirect_url_not_allowed',
                    redirect_url: redirect_url
                  )
                  redirect_params['message'] = message
                  next "#{::OmniAuth.config.path_prefix}/failure?#{redirect_params.to_param}"
                end
              end

              # re-construct the path for omniauth
              "#{::OmniAuth.config.path_prefix}/#{params[:provider]}?#{redirect_params.to_param}"
            }, via: [:get, :post]
          end
        end
      end
    end

    # this allows us to use namespaced paths without namespacing the routes
    def unnest_namespace
      current_scope = @scope.dup
      yield
    ensure
      @scope = current_scope
    end

    # ignore error about omniauth/multiple model support
    def set_omniauth_path_prefix!(path_prefix)
      ::OmniAuth.config.path_prefix = path_prefix
    end
  end
end
