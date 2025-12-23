require 'sentry/sidekiq/context_filter'

module Sentry
  module Sidekiq
    class ErrorHandler
      WITH_SIDEKIQ_7 = ::Gem::Version.new(::Sidekiq::VERSION) >= ::Gem::Version.new("7.0")

      # @param ex [Exception] the exception / error that occured
      # @param context [Hash or Array] Sidekiq error context
      # @param sidekiq_config [Sidekiq::Config, Hash] Sidekiq configuration,
      #   Defaults to nil.
      #   Sidekiq will pass the config in starting Sidekiq 7.1.5, see
      #   https://github.com/sidekiq/sidekiq/pull/6051
      def call(ex, context, sidekiq_config = nil)
        return unless Sentry.initialized?

        context_filter = Sentry::Sidekiq::ContextFilter.new(context)

        scope = Sentry.get_current_scope
        scope.set_transaction_name(context_filter.transaction_name, source: :task) unless scope.transaction_name

        # If Sentry is configured to only report an error _after_ all retries have been exhausted,
        # and if the job is retryable, and have not exceeded the retry_limit,
        # return early.
        if Sentry.configuration.sidekiq.report_after_job_retries && retryable?(context)
          retry_count = context.dig(:job, "retry_count")
          if retry_count.nil? || retry_count < retry_limit(context, sidekiq_config) - 1
            return
          end
        end

        Sentry::Sidekiq.capture_exception(
          ex,
          contexts: { sidekiq: context_filter.filtered },
          hint: { background: false }
        )
      ensure
        scope&.clear
      end

      private

      def retryable?(context)
        retry_option = context.dig(:job, "retry")
        # when `retry` is not specified, it's default is `true` and it means 25 retries.
        retry_option == true || (retry_option.is_a?(Integer) && retry_option.positive?)
      end

      # @return [Integer] the number of retries allowed for the job
      # Tries to fetch the retry limit from the job config first,
      # then falls back to Sidekiq's configuration.
      def retry_limit(context, sidekiq_config)
        limit = context.dig(:job, "retry")

        case limit
        when Integer
          limit
        when TrueClass
          max_retries =
            if WITH_SIDEKIQ_7
              # Sidekiq 7.1.5+ passes the config to the error handler, so we should use that.
              # Sidekiq 7.0 -> 7.1.5 provides ::Sidekiq.default_configuration.
              sidekiq_config.is_a?(::Sidekiq::Config) ?
                sidekiq_config[:max_retries] :
                ::Sidekiq.default_configuration[:max_retries]
            else
              ::Sidekiq.options[:max_retries]
            end
          max_retries || 25
        else
          0
        end
      end
    end
  end
end
