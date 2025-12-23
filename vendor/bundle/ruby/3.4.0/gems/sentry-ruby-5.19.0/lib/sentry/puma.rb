# frozen_string_literal: true

return unless defined?(Puma::Server)

module Sentry
  module Puma
    module Server
      PUMA_4_AND_PRIOR = Gem::Version.new(::Puma::Const::PUMA_VERSION) < Gem::Version.new("5.0.0")

      def lowlevel_error(e, env, status = 500)
        result =
          if PUMA_4_AND_PRIOR
            super(e, env)
          else
            super
          end

        begin
          Sentry.capture_exception(e) do |scope|
            scope.set_rack_env(env)
          end
        rescue
          # if anything happens, we don't want to break the app
        end

        result
      end
    end
  end
end

Sentry.register_patch(:puma, Sentry::Puma::Server, Puma::Server)
