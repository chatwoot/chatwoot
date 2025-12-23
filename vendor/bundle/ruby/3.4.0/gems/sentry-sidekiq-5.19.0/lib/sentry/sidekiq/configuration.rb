module Sentry
  class Configuration
    attr_reader :sidekiq

    add_post_initialization_callback do
      @sidekiq = Sentry::Sidekiq::Configuration.new
      @excluded_exceptions = @excluded_exceptions.concat(Sentry::Sidekiq::IGNORE_DEFAULT)
    end
  end

  module Sidekiq
    IGNORE_DEFAULT = ["Sidekiq::JobRetry::Skip"]

    class Configuration
      # Set this option to true if you want Sentry to only capture the last job
      # retry if it fails.
      attr_accessor :report_after_job_retries

      def initialize
        @report_after_job_retries = false
      end
    end
  end
end
