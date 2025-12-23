module OmniAuth
  class Builder < ::Rack::Builder
    def on_failure(&block)
      OmniAuth.config.on_failure = block
    end

    def before_options_phase(&block)
      OmniAuth.config.before_options_phase = block
    end

    def before_request_phase(&block)
      OmniAuth.config.before_request_phase = block
    end

    def after_request_phase(&block)
      OmniAuth.config.after_request_phase = block
    end

    def before_callback_phase(&block)
      OmniAuth.config.before_callback_phase = block
    end

    def configure(&block)
      OmniAuth.configure(&block)
    end

    def options(options = false)
      return @options ||= {} if options == false

      @options = options
    end

    def provider(klass, *args, **opts, &block)
      if klass.is_a?(Class)
        middleware = klass
      else
        begin
          middleware = OmniAuth::Strategies.const_get(OmniAuth::Utils.camelize(klass.to_s).to_s, false)
        rescue NameError
          raise(LoadError.new("Could not find matching strategy for #{klass.inspect}. You may need to install an additional gem (such as omniauth-#{klass})."))
        end
      end

      use middleware, *args, **options.merge(opts), &block
    end

    def call(env)
      to_app.call(env)
    end
  end
end
