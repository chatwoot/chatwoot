require "sentry/rails/tracing/action_controller_subscriber"
require "sentry/rails/tracing/action_view_subscriber"
require "sentry/rails/tracing/active_record_subscriber"
require "sentry/rails/tracing/active_storage_subscriber"

module Sentry
  class Configuration
    attr_reader :rails

    add_post_initialization_callback do
      @rails = Sentry::Rails::Configuration.new
      @excluded_exceptions = @excluded_exceptions.concat(Sentry::Rails::IGNORE_DEFAULT)

      if ::Rails.logger
        if defined?(::ActiveSupport::BroadcastLogger) && ::Rails.logger.is_a?(::ActiveSupport::BroadcastLogger)
          dupped_broadcasts = ::Rails.logger.broadcasts.map(&:dup)
          @logger = ::ActiveSupport::BroadcastLogger.new(*dupped_broadcasts)
        else
          @logger = ::Rails.logger.dup
        end
      else
        @logger.warn(Sentry::LOGGER_PROGNAME) do
          <<~MSG
          sentry-rails can't detect Rails.logger. it may be caused by misplacement of the SDK initialization code
          please make sure you place the Sentry.init block under the `config/initializers` folder, e.g. `config/initializers/sentry.rb`
          MSG
        end
      end
    end
  end

  module Rails
    IGNORE_DEFAULT = [
      'AbstractController::ActionNotFound',
      'ActionController::BadRequest',
      'ActionController::InvalidAuthenticityToken',
      'ActionController::InvalidCrossOriginRequest',
      'ActionController::MethodNotAllowed',
      'ActionController::NotImplemented',
      'ActionController::ParameterMissing',
      'ActionController::RoutingError',
      'ActionController::UnknownAction',
      'ActionController::UnknownFormat',
      'ActionDispatch::Http::MimeNegotiation::InvalidType',
      'ActionController::UnknownHttpMethod',
      'ActionDispatch::Http::Parameters::ParseError',
      'ActiveRecord::RecordNotFound'
    ].freeze

    ACTIVE_SUPPORT_LOGGER_SUBSCRIPTION_ITEMS_DEFAULT = {
      # action_controller
      "write_fragment.action_controller" => %i[key],
      "read_fragment.action_controller" => %i[key],
      "exist_fragment?.action_controller" => %i[key],
      "expire_fragment.action_controller" => %i[key],
      "start_processing.action_controller" => %i[controller action params format method path],
      "process_action.action_controller" => %i[controller action params format method path status view_runtime db_runtime],
      "send_file.action_controller" => %i[path],
      "redirect_to.action_controller" => %i[status location],
      "halted_callback.action_controller" => %i[filter],
      # action_dispatch
      "process_middleware.action_dispatch" => %i[middleware],
      # action_view
      "render_template.action_view" => %i[identifier layout],
      "render_partial.action_view" => %i[identifier],
      "render_collection.action_view" => %i[identifier count cache_hits],
      "render_layout.action_view" => %i[identifier],
      # active_record
      "sql.active_record" => %i[sql name statement_name cached],
      "instantiation.active_record" => %i[record_count class_name],
      # action_mailer
      # not including to, from, or subject..etc. because of PII concern
      "deliver.action_mailer" => %i[mailer date perform_deliveries],
      "process.action_mailer" => %i[mailer action params],
      # active_support
      "cache_read.active_support" => %i[key store hit],
      "cache_generate.active_support" => %i[key store],
      "cache_fetch_hit.active_support" => %i[key store],
      "cache_write.active_support" => %i[key store],
      "cache_delete.active_support" => %i[key store],
      "cache_exist?.active_support" => %i[key store],
      # active_job
      "enqueue_at.active_job" => %i[],
      "enqueue.active_job" => %i[],
      "enqueue_retry.active_job" => %i[],
      "perform_start.active_job" => %i[],
      "perform.active_job" => %i[],
      "retry_stopped.active_job" => %i[],
      "discard.active_job" => %i[],
      # action_cable
      "perform_action.action_cable" => %i[channel_class action],
      "transmit.action_cable" => %i[channel_class],
      "transmit_subscription_confirmation.action_cable" => %i[channel_class],
      "transmit_subscription_rejection.action_cable" => %i[channel_class],
      "broadcast.action_cable" => %i[broadcasting],
      # active_storage
      "service_upload.active_storage" => %i[service key checksum],
      "service_streaming_download.active_storage" => %i[service key],
      "service_download_chunk.active_storage" => %i[service key],
      "service_download.active_storage" => %i[service key],
      "service_delete.active_storage" => %i[service key],
      "service_delete_prefixed.active_storage" => %i[service prefix],
      "service_exist.active_storage" => %i[service key exist],
      "service_url.active_storage" => %i[service key url],
      "service_update_metadata.active_storage" => %i[service key],
      "preview.active_storage" => %i[key],
      "analyze.active_storage" => %i[analyzer]
    }.freeze

    class Configuration
      # Rails 7.0 introduced a new error reporter feature, which the SDK once opted-in by default.
      # But after receiving multiple issue reports, the integration seemed to cause serious troubles to some users.
      # So the integration is now controlled by this configuration, which is disabled (false) by default.
      # More information can be found from: https://github.com/rails/rails/pull/43625#issuecomment-1072514175
      attr_accessor :register_error_subscriber

      # Rails catches exceptions in the ActionDispatch::ShowExceptions or
      # ActionDispatch::DebugExceptions middlewares, depending on the environment.
      # When `report_rescued_exceptions` is true (it is by default), Sentry will
      # report exceptions even when they are rescued by these middlewares.
      attr_accessor :report_rescued_exceptions

      # Some adapters, like sidekiq, already have their own sentry integration.
      # In those cases, we should skip ActiveJob's reporting to avoid duplicated reports.
      attr_accessor :skippable_job_adapters

      attr_accessor :tracing_subscribers

      # When the ActiveRecordSubscriber is enabled, capture the source location of the query in the span data.
      # This is enabled by default, but can be disabled by setting this to false.
      attr_accessor :enable_db_query_source

      # The threshold in milliseconds for the ActiveRecordSubscriber to capture the source location of the query
      # in the span data. Default is 100ms.
      attr_accessor :db_query_source_threshold_ms

      # sentry-rails by default skips asset request' transactions by checking if the path matches
      #
      # ```rb
      # %r(\A/{0,2}#{::Rails.application.config.assets.prefix})
      # ```
      #
      # If you want to use a different pattern, you can configure the `assets_regexp` option like:
      #
      # ```rb
      # Sentry.init do |config|
      #   config.rails.assets_regexp = /my_regexp/
      # end
      # ```
      attr_accessor :assets_regexp

      # Hash of subscription items that will be shown in breadcrumbs active support logger.
      # @return [Hash<String, Array<Symbol>>]
      attr_accessor :active_support_logger_subscription_items

      def initialize
        @register_error_subscriber = false
        @report_rescued_exceptions = true
        @skippable_job_adapters = []
        @assets_regexp = if defined?(::Sprockets::Rails)
          %r(\A/{0,2}#{::Rails.application.config.assets.prefix})
        end
        @tracing_subscribers = Set.new([
          Sentry::Rails::Tracing::ActionViewSubscriber,
          Sentry::Rails::Tracing::ActiveRecordSubscriber,
          Sentry::Rails::Tracing::ActiveStorageSubscriber
        ])
        @enable_db_query_source = true
        @db_query_source_threshold_ms = 100
        @active_support_logger_subscription_items = Sentry::Rails::ACTIVE_SUPPORT_LOGGER_SUBSCRIPTION_ITEMS_DEFAULT.dup
      end
    end
  end
end
