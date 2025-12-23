require 'singleton'

# Used to retrieve environment information for this application.
module ScoutApm
  class Environment
    include Singleton

    STDOUT_LOGGER = begin
                      l = Logger.new(STDOUT)
                      l.level = Logger::INFO
                      l
                    end

    # I've put Thin and Webrick last as they are often used in development and included in Gemfiles
    # but less likely used in production.
    SERVER_INTEGRATIONS = [
      ScoutApm::ServerIntegrations::Passenger.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Unicorn.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Rainbows.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Puma.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Thin.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Webrick.new(STDOUT_LOGGER),
      ScoutApm::ServerIntegrations::Null.new(STDOUT_LOGGER), # must be last
    ]

    BACKGROUND_JOB_INTEGRATIONS = [
      ScoutApm::BackgroundJobIntegrations::Resque.new,
      ScoutApm::BackgroundJobIntegrations::Sidekiq.new,
      ScoutApm::BackgroundJobIntegrations::Shoryuken.new,
      ScoutApm::BackgroundJobIntegrations::Sneakers.new,
      ScoutApm::BackgroundJobIntegrations::DelayedJob.new,
      ScoutApm::BackgroundJobIntegrations::Que.new,
      ScoutApm::BackgroundJobIntegrations::Faktory.new,
    ]

    FRAMEWORK_INTEGRATIONS = [
      ScoutApm::FrameworkIntegrations::Rails2.new,
      ScoutApm::FrameworkIntegrations::Rails3Or4.new,
      ScoutApm::FrameworkIntegrations::Sinatra.new,
      ScoutApm::FrameworkIntegrations::Ruby.new, # Fallback if none match
    ]

    PLATFORM_INTEGRATIONS = [
      ScoutApm::PlatformIntegrations::Heroku.new,
      ScoutApm::PlatformIntegrations::CloudFoundry.new,
      ScoutApm::PlatformIntegrations::Server.new,
    ]

    def env
      @env ||= framework_integration.env
    end

    def framework
      framework_integration.name
    end

    def framework_integration
      @framework ||= FRAMEWORK_INTEGRATIONS.detect{ |integration| integration.present? }
    end

    def platform_integration
      @platform ||= PLATFORM_INTEGRATIONS.detect{ |integration| integration.present? }
    end

    def application_name
      Agent.instance.context.config.value("name") ||
        framework_integration.application_name ||
        "App"
    end

    def database_engine
      framework_integration.database_engine
    end

    def raw_database_adapter
      framework_integration.raw_database_adapter
    end

    def processors
      @processors ||= begin
                        proc_file = '/proc/cpuinfo'
                        processors = if !File.exist?(proc_file)
                                       1
                                     else
                                       lines = File.read("/proc/cpuinfo").lines.to_a
                                       lines.grep(/^processor\s*:/i).size
                                     end
                        [processors, 1].compact.max
                      end
    end

    def scm_subdirectory
      @scm_subdirectory ||= if Agent.instance.context.config.value('scm_subdirectory').empty?
        ''
      else
        Agent.instance.context.config.value('scm_subdirectory').sub(/^\//, '') # Trim any leading slash
      end
    end

    def root
      @root ||= framework_root
    end

    def framework_root
      if override_root = Agent.instance.context.config.value("application_root")
        return override_root
      end
      if framework == :rails
        RAILS_ROOT.to_s
      elsif framework == :rails3_or_4
        Rails.root
      elsif framework == :sinatra
        Sinatra::Application.root || "."
      else
        '.'
      end
    end

    def hostname
      @hostname ||= Agent.instance.context.config.value("hostname") || platform_integration.hostname
    end

    def git_revision
      @git_revision ||= ScoutApm::GitRevision.new(Agent.instance.context)
    end

    # Returns the whole integration object
    # This needs to be improved. Frequently, multiple app servers gem are present and which
    # ever is checked first becomes the designated app server.
    #
    # Next step: (1) list out all detected app servers (2) install hooks for those that need it (passenger, rainbows, unicorn).
    def app_server_integration(force=false)
      @app_server = nil if force
      @app_server ||= SERVER_INTEGRATIONS.detect{ |integration| integration.present? }
    end

    # App server's name (symbol)
    def app_server
      app_server_integration.name
    end

    # If forking, don't start worker thread in the master process. Since it's
    # started as a Thread, it won't survive the fork.
    def forking?
      app_server_integration.forking? || (background_job_integration && background_job_integration.forking?)
    end

    def background_job_integrations
      if Agent.instance.context.config.value("enable_background_jobs")
        @background_job_integrations ||= BACKGROUND_JOB_INTEGRATIONS.select {|integration| integration.present?}
      else
        []
      end
    end

    # If both stdin & stdout are interactive and the Rails::Console constant is defined
    def interactive?
      defined?(::Rails::Console) && $stdout.isatty && $stdin.isatty
    end

    ### ruby checks

    def rubinius?
      RUBY_VERSION =~ /rubinius/i
    end

    def jruby?
      defined?(JRuby)
    end

    def ruby_19?
      return @ruby_19 if defined?(@ruby_19)
      @ruby_19 = defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION.match(/^1\.9/)
    end

    def ruby_187?
      return @ruby_187 if defined?(@ruby_187)
      @ruby_187 = defined?(RUBY_VERSION) && RUBY_VERSION.match(/^1\.8\.7/)
    end

    def ruby_2?
      return @ruby_2 if defined?(@ruby_2)
      @ruby_2 = defined?(RUBY_VERSION) && RUBY_VERSION.match(/^2/)
    end

    def ruby_3?
      return @ruby_3 if defined?(@ruby_3)
      @ruby_3 = defined?(RUBY_VERSION) && RUBY_VERSION.match(/^3/)
    end

    def ruby_minor
      return @ruby_minor if defined?(@ruby_minor)
      @ruby_minor = defined?(RUBY_VERSION) && RUBY_VERSION.split(".")[1].to_i
    end

    # Returns true if this Ruby version supports Module#prepend.
    def supports_module_prepend?
      ruby_2? || ruby_3?
    end

    # Returns true if this Ruby version makes positional and keyword arguments incompatible
    def supports_kwarg_delegation?
      ruby_3? || (ruby_2? && ruby_minor >= 7)
    end

    # Returns a string representation of the OS (ex: darwin, linux)
    def os
      return @os if @os
      raw_os = RbConfig::CONFIG['target_os']
      match = raw_os.match(/([a-z]+)/)
      if match
        @os = match[1]
      else
        @os = raw_os
      end
    end

    ### framework checks

    def sinatra?
      framework_integration.name == :sinatra
    end
  end # class Environemnt
end
