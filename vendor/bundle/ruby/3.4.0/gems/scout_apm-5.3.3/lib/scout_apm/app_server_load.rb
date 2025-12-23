module ScoutApm
  class AppServerLoad
    attr_reader :logger
    attr_reader :context

    def initialize(context)
      @context = context
      @logger = context.logger
    end

    def run
      @thread = Thread.new do
        begin
          logger.info "Sending Application Startup Info - App Server: #{data[:app_server]}, Framework: #{data[:framework]}, Framework Version: #{data[:framework_version]}, Database Engine: #{data[:database_engine]}"
          logger.debug("Full Application Startup Info: #{data.inspect}")

          payload = ScoutApm::Serializers::AppServerLoadSerializer.serialize(data)
          reporter = Reporter.new(context, :app_server_load)
          reporter.report(payload)

          logger.debug("Finished sending Startup Info")
        rescue => e
          logger.info("Failed Sending Application Startup Info - #{e.message}")
          logger.debug(e.backtrace.join("\t\n"))
        end
      end
    rescue => e
      logger.debug("Failed Startup Info - #{e.message} \n\t#{e.backtrace.join("\t\n")}")
    end

    def data
      { 
        :language           => 'ruby',
        :language_version   => RUBY_VERSION,
        :ruby_version       => RUBY_VERSION, # Deprecated.

        :framework          => to_s_safe(environment.framework_integration.human_name),
        :framework_version  => to_s_safe(environment.framework_integration.version),

        :server_time        => to_s_safe(Time.now),
        :environment        => to_s_safe(environment.framework_integration.env),
        :app_server         => to_s_safe(environment.app_server),
        :hostname           => to_s_safe(environment.hostname),
        :database_engine    => to_s_safe(environment.database_engine),      # Detected
        :database_adapter   => to_s_safe(environment.raw_database_adapter), # Raw
        :application_name   => to_s_safe(environment.application_name),
        :libraries          => ScoutApm::Utils::InstalledGems.new(context).run,
        :paas               => to_s_safe(environment.platform_integration.name),
        :git_sha            => to_s_safe(environment.git_revision.sha)
      }
    ensure
      # Sometimes :database_engine and :database_adapter can cause a reference to an AR connection.
      # Make sure we release all AR connections held by this thread.
      ActiveRecord::Base.clear_active_connections! if Utils::KlassHelper.defined?("ActiveRecord::Base")
    end

    # Calls `.to_s` on the object passed in.
    # Returns literal string 'to_s error' if the object does not respond to .to_s
    def to_s_safe(obj)
      if obj.respond_to?(:to_s)
        obj.to_s
      else
        'to_s error'
      end
    end

    def environment
      context.environment
    end
  end
end
