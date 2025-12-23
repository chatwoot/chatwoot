module Sentry
  module Rails
    # This is not a user-facing class. You should use it with Rails 7.0's error reporter feature and its interfaces.
    # See https://github.com/rails/rails/blob/main/activesupport/lib/active_support/error_reporter.rb to learn more about reporting APIs.
    # If you want Sentry to subscribe to the error reporter, please set `config.rails.register_error_subscriber` to `true`.
    class ErrorSubscriber
      SKIP_SOURCES = Regexp.union([/.*_cache_store.active_support/])

      def report(error, handled:, severity:, context:, source: nil)
        tags = { handled: handled }

        if source
          return if SKIP_SOURCES.match?(source)
          tags[:source] = source
        end

        if context[:tags].is_a?(Hash)
          context = context.dup
          tags.merge!(context.delete(:tags))
        end

        hint = {}
        if context[:hint].is_a?(Hash)
          context = context.dup
          hint.merge!(context.delete(:hint))
        end

        Sentry::Rails.capture_exception(error, level: severity, contexts: { "rails.error" => context }, tags: tags, hint: hint)
      end
    end
  end
end
