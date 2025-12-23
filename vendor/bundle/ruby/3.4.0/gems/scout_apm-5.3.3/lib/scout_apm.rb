module ScoutApm
end

#####################################
# Ruby StdLibrary Requires
#####################################
require 'cgi'
require 'logger'
require 'monitor'
require 'net/http'
require 'openssl'
require 'pp'
require 'set'
require 'socket'
require 'thread'
require 'time'
require 'yaml'
require 'securerandom'

#####################################
# Gem Requires
#####################################
require 'rusage'

#####################################
# Internal Requires
#####################################
require 'scout_apm/version'

require 'scout_apm/exceptions'
require 'scout_apm/debug'
require 'scout_apm/tracked_request'
require 'scout_apm/layer'
require 'scout_apm/limited_layer'
require 'scout_apm/layer_children_set'
require 'scout_apm/request_manager'
require 'scout_apm/call_set'

require 'scout_apm/layer_converters/converter_base'
require 'scout_apm/layer_converters/depth_first_walker'
require 'scout_apm/layer_converters/error_converter'
require 'scout_apm/layer_converters/job_converter'
require 'scout_apm/layer_converters/slow_job_converter'
require 'scout_apm/layer_converters/metric_converter'
require 'scout_apm/layer_converters/database_converter'
require 'scout_apm/layer_converters/external_service_converter'
require 'scout_apm/layer_converters/slow_request_converter'
require 'scout_apm/layer_converters/request_queue_time_converter'
require 'scout_apm/layer_converters/allocation_metric_converter'
require 'scout_apm/layer_converters/trace_converter'
require 'scout_apm/layer_converters/histograms'
require 'scout_apm/layer_converters/find_layer_by_type'

require 'scout_apm/server_integrations/passenger'
require 'scout_apm/server_integrations/puma'
require 'scout_apm/server_integrations/rainbows'
require 'scout_apm/server_integrations/thin'
require 'scout_apm/server_integrations/unicorn'
require 'scout_apm/server_integrations/webrick'
require 'scout_apm/server_integrations/null'

require 'scout_apm/background_job_integrations/sidekiq'
require 'scout_apm/background_job_integrations/faktory'
require 'scout_apm/background_job_integrations/delayed_job'
require 'scout_apm/background_job_integrations/resque'
require 'scout_apm/background_job_integrations/shoryuken'
require 'scout_apm/background_job_integrations/sneakers'
require 'scout_apm/background_job_integrations/que'
require 'scout_apm/background_job_integrations/legacy_sneakers'

require 'scout_apm/framework_integrations/rails_2'
require 'scout_apm/framework_integrations/rails_3_or_4'
require 'scout_apm/framework_integrations/sinatra'
require 'scout_apm/framework_integrations/ruby'

require 'scout_apm/platform_integrations/heroku'
require 'scout_apm/platform_integrations/cloud_foundry'
require 'scout_apm/platform_integrations/server'

require 'scout_apm/histogram'

require 'scout_apm/instruments/net_http'
require 'scout_apm/instruments/http_client'
require 'scout_apm/instruments/http'
require 'scout_apm/instruments/typhoeus'
require 'scout_apm/instruments/moped'
require 'scout_apm/instruments/mongoid'
require 'scout_apm/instruments/memcached'
require 'scout_apm/instruments/redis'
require 'scout_apm/instruments/redis5'
require 'scout_apm/instruments/influxdb'
require 'scout_apm/instruments/elasticsearch'
require 'scout_apm/instruments/active_record'
require 'scout_apm/instruments/action_controller_rails_2'
require 'scout_apm/instruments/action_controller_rails_3_rails4'
require 'scout_apm/instruments/action_view'
require 'scout_apm/instruments/middleware_summary'
require 'scout_apm/instruments/middleware_detailed' # Disabled by default, see the file for more details
require 'scout_apm/instruments/rails_router'
require 'scout_apm/instruments/grape'
require 'scout_apm/instruments/sinatra'
require 'allocations'

require 'scout_apm/instruments/process/process_cpu'
require 'scout_apm/instruments/process/process_memory'
require 'scout_apm/instruments/percentile_sampler'
require 'scout_apm/instruments/samplers'

require 'scout_apm/app_server_load'

require 'scout_apm/ignored_uris.rb'
require 'scout_apm/utils/active_record_metric_name'
require 'scout_apm/utils/backtrace_parser'
require 'scout_apm/utils/installed_gems'
require 'scout_apm/utils/klass_helper'
require 'scout_apm/utils/scm'
require 'scout_apm/utils/sql_sanitizer'
require 'scout_apm/utils/time'
require 'scout_apm/utils/unique_id'
require 'scout_apm/utils/numbers'
require 'scout_apm/utils/gzip_helper'
require 'scout_apm/utils/marshal_logging'

require 'scout_apm/config'
require 'scout_apm/environment'
require 'scout_apm/agent'
require 'scout_apm/logger'
require 'scout_apm/reporting'
require 'scout_apm/layaway'
require 'scout_apm/layaway_file'
require 'scout_apm/reporter'
require 'scout_apm/background_worker'
require 'scout_apm/bucket_name_splitter'
require 'scout_apm/stack_item'
require 'scout_apm/metric_set'
require 'scout_apm/db_query_metric_set'
require 'scout_apm/external_service_metric_set'
require 'scout_apm/store'
require 'scout_apm/fake_store'
require 'scout_apm/tracer'
require 'scout_apm/transaction'
require 'scout_apm/context'
require 'scout_apm/instant_reporting'
require 'scout_apm/background_recorder'
require 'scout_apm/synchronous_recorder'

require 'scout_apm/metric_meta'
require 'scout_apm/metric_stats'
require 'scout_apm/db_query_metric_stats'
require 'scout_apm/external_service_metric_stats'
require 'scout_apm/slow_transaction'
require 'scout_apm/slow_job_record'
require 'scout_apm/detailed_trace'
require 'scout_apm/scored_item_set'

require 'scout_apm/slow_request_policy'
require 'scout_apm/slow_policy/age_policy'
require 'scout_apm/slow_policy/speed_policy'
require 'scout_apm/slow_policy/percent_policy'
require 'scout_apm/slow_policy/percentile_policy'

require 'scout_apm/job_record'
require 'scout_apm/request_histograms'
require 'scout_apm/transaction_time_consumed'

require 'scout_apm/attribute_arranger'
require 'scout_apm/git_revision'

require 'scout_apm/serializers/payload_serializer'
require 'scout_apm/serializers/payload_serializer_to_json'
require 'scout_apm/serializers/jobs_serializer_to_json'
require 'scout_apm/serializers/slow_jobs_serializer_to_json'
require 'scout_apm/serializers/metrics_to_json_serializer'
require 'scout_apm/serializers/histograms_serializer_to_json'
require 'scout_apm/serializers/db_query_serializer_to_json'
require 'scout_apm/serializers/external_service_serializer_to_json'
require 'scout_apm/serializers/directive_serializer'
require 'scout_apm/serializers/app_server_load_serializer'

require 'scout_apm/middleware'

require 'scout_apm/instant/middleware'

require 'scout_apm/rack'

require 'scout_apm/remote/server'
require 'scout_apm/remote/router'
require 'scout_apm/remote/message'
require 'scout_apm/remote/recorder'
require 'scout_apm/instruments/resque'

require 'scout_apm/agent_context'
require 'scout_apm/instrument_manager'
require 'scout_apm/periodic_work'
require 'scout_apm/agent/preconditions'
require 'scout_apm/agent/exit_handler'
require 'scout_apm/tasks/doctor'
require 'scout_apm/tasks/support'

require 'scout_apm/extensions/config'
require 'scout_apm/extensions/transaction_callback_payload'

require 'scout_apm/error'
require 'scout_apm/error_service'
require 'scout_apm/error_service/middleware'
require 'scout_apm/error_service/notifier'
require 'scout_apm/error_service/sidekiq'
require 'scout_apm/error_service/ignored_exceptions'
require 'scout_apm/error_service/error_buffer'
require 'scout_apm/error_service/error_record'
require 'scout_apm/error_service/periodic_work'
require 'scout_apm/error_service/payload'

if defined?(Rails) && defined?(Rails::VERSION) && defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR >= 3 && defined?(Rails::Railtie)
  module ScoutApm
    class Railtie < Rails::Railtie
      initializer 'scout_apm.start' do |app|
        # attempt to start on first-request if not otherwise started, which is
        # a good catch-all for Webrick, and Passenger and similar, where we
        # can't detect the running app server until actual requests come in.
        app.middleware.use ScoutApm::Middleware

        # Attempt to start right away, this will work best for preloading apps, Unicorn & Puma & similar
        ScoutApm::Agent.instance.install

        if ScoutApm::Agent.instance.context.config.value("auto_instruments")
          if defined?(Parser::TreeRewriter)
            ScoutApm::Agent.instance.context.logger.debug("AutoInstruments is enabled.")
            require 'scout_apm/auto_instrument'
          else # AutoInstruments is turned on, but we don't he the prerequisites to use it
            ScoutApm::Agent.instance.context.logger.debug("AutoInstruments is enabled, but Parser::TreeRewriter is missing. Update 'parser' gem to >= 2.5.0.")
          end
        else
          ScoutApm::Agent.instance.context.logger.debug("AutoInstruments is disabled.")
        end

        if ScoutApm::Agent.instance.context.config.value("errors_enabled")
          app.config.middleware.insert_after ActionDispatch::DebugExceptions, ScoutApm::ErrorService::Middleware
          ScoutApm::ErrorService::Sidekiq.new.install
        end

        # Install the middleware every time in development mode.
        # The middleware is a noop if dev_trace is not enabled in config
        if Rails.env.development?
          app.middleware.use ScoutApm::Instant::Middleware
        end
      end

      rake_tasks do
        load "tasks/doctor.rake"
      end
    end
  end
else
  ScoutApm::Agent.instance.install
end
