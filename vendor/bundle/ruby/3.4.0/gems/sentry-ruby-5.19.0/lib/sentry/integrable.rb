# frozen_string_literal: true

module Sentry
  module Integrable
    def register_integration(name:, version:)
      Sentry.register_integration(name, version)
      @integration_name = name
    end

    def integration_name
      @integration_name
    end

    def capture_exception(exception, **options, &block)
      options[:hint] ||= {}
      options[:hint][:integration] = integration_name

      # within an integration, we usually intercept uncaught exceptions so we set handled to false.
      options[:hint][:mechanism] ||= Sentry::Mechanism.new(type: integration_name, handled: false)

      Sentry.capture_exception(exception, **options, &block)
    end

    def capture_message(message, **options, &block)
      options[:hint] ||= {}
      options[:hint][:integration] = integration_name
      Sentry.capture_message(message, **options, &block)
    end

    def capture_check_in(slug, status, **options, &block)
      options[:hint] ||= {}
      options[:hint][:integration] = integration_name
      Sentry.capture_check_in(slug, status, **options, &block)
    end
  end
end
