# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'set'
require 'new_relic/version'

module NewRelic
  # This class is responsible for determining the 'dispatcher' in use by the
  # current process. The dispatcher might be a recognized web server such as
  # unicorn or passenger, a background job processor such as resque or sidekiq,
  # or nil for unknown.
  #
  # Dispatcher detection is best-effort, and serves two purposes:
  #
  # 1. For some dispatchers, we need to apply specific workarounds in order for
  #    the agent to work correctly.
  # 2. When reading logs, since multiple processes on a given host might write
  #    into the same log, it's useful to be able to identify what kind of
  #    process a given PID mapped to.
  #
  # Overriding the dispatcher is possible via the NEW_RELIC_DISPATCHER
  # environment variable, but this should not generally be necessary unless
  # you're on a dispatcher that falls into category 1 above, and our detection
  # logic isn't working correctly.
  #
  # If the environment can't be determined, it will be set to nil.
  #
  # NewRelic::LocalEnvironment should be accessed through NewRelic::Control#local_env (via the NewRelic::Control singleton).
  class LocalEnvironment
    def discovered_dispatcher
      discover_dispatcher unless @discovered_dispatcher
      @discovered_dispatcher
    end

    def initialize
      # Extend self with any submodules of LocalEnvironment.  These can override
      # the discover methods to discover new frameworks and dispatchers.
      NewRelic::LocalEnvironment.constants.each do |const|
        mod = NewRelic::LocalEnvironment.const_get(const)
        self.extend(mod) if mod.instance_of?(Module)
      end

      @discovered_dispatcher = nil
      discover_dispatcher
    end

    # Runs through all the objects in ObjectSpace to find the first one that
    # match the provided class
    def find_class_in_object_space(klass)
      if NewRelic::LanguageSupport.object_space_usable?
        ObjectSpace.each_object(klass) do |x|
          return x
        end
      end
      return nil
    end

    private

    def discover_dispatcher
      dispatchers = %w[
        passenger
        torquebox
        trinidad
        glassfish
        resque
        sidekiq
        delayed_job
        puma
        thin
        mongrel
        litespeed
        unicorn
        webrick
        fastcgi
      ]
      while dispatchers.any? && @discovered_dispatcher.nil?
        send('check_for_' + (dispatchers.shift))
      end
    end

    def check_for_torquebox
      return unless defined?(::JRuby) &&
        (org.torquebox::TorqueBox rescue nil)

      @discovered_dispatcher = :torquebox
    end

    def check_for_glassfish
      return unless defined?(::JRuby) &&
        (((com.sun.grizzly.jruby.rack.DefaultRackApplicationFactory rescue nil) &&
          defined?(com::sun::grizzly::jruby::rack::DefaultRackApplicationFactory)) ||
         (jruby_rack? && defined?(::GlassFish::Server)))

      @discovered_dispatcher = :glassfish
    end

    def check_for_trinidad
      return unless defined?(::JRuby) && jruby_rack? && defined?(::Trinidad::Server)

      @discovered_dispatcher = :trinidad
    end

    def jruby_rack?
      defined?(JRuby::Rack::VERSION)
    end

    def check_for_webrick
      return unless defined?(::WEBrick) && defined?(::WEBrick::VERSION)

      @discovered_dispatcher = :webrick
    end

    def check_for_fastcgi
      return unless defined?(::FCGI)

      @discovered_dispatcher = :fastcgi
    end

    # this case covers starting by mongrel_rails
    def check_for_mongrel
      return unless defined?(::Mongrel) && defined?(::Mongrel::HttpServer)

      @discovered_dispatcher = :mongrel
    end

    def check_for_unicorn
      if (defined?(::Unicorn) && defined?(::Unicorn::HttpServer)) && NewRelic::LanguageSupport.object_space_usable?
        v = find_class_in_object_space(::Unicorn::HttpServer)
        @discovered_dispatcher = :unicorn if v
      end
    end

    def check_for_puma
      if defined?(::Puma) && File.basename($0) == 'puma'
        @discovered_dispatcher = :puma
      end
    end

    def check_for_delayed_job
      if $0 =~ /delayed_job$/ || (File.basename($0) == 'rake' && ARGV.include?('jobs:work'))
        @discovered_dispatcher = :delayed_job
      end
    end

    def check_for_resque
      has_queue = ENV['QUEUE'] || ENV['QUEUES']
      resque_rake = executable == 'rake' && ARGV.include?('resque:work')
      resque_pool_rake = executable == 'rake' && ARGV.include?('resque:pool')
      resque_pool_executable = executable == 'resque-pool' && defined?(::Resque::Pool)

      using_resque = defined?(::Resque) &&
        (has_queue && resque_rake) ||
        (resque_pool_executable || resque_pool_rake)

      @discovered_dispatcher = :resque if using_resque
    end

    def check_for_sidekiq
      if defined?(::Sidekiq) && File.basename($0) == 'sidekiq'
        @discovered_dispatcher = :sidekiq
      end
    end

    def check_for_thin
      if defined?(::Thin) && defined?(::Thin::Server)
        # If ObjectSpace is available, use it to search for a Thin::Server
        # instance. Otherwise, just the presence of the constant is sufficient.
        if NewRelic::LanguageSupport.object_space_usable?
          ObjectSpace.each_object(Thin::Server) do |thin_dispatcher|
            @discovered_dispatcher = :thin
          end
        else
          @discovered_dispatcher = :thin
        end
      end
    end

    def check_for_litespeed
      if caller.pop.include?('fcgi-bin/RailsRunner.rb')
        @discovered_dispatcher = :litespeed
      end
    end

    def check_for_passenger
      if defined?(::PhusionPassenger)
        @discovered_dispatcher = :passenger
      end
    end

    public

    # outputs a human-readable description
    def to_s
      %Q(LocalEnvironment[#{";dispatcher=#{@discovered_dispatcher}" if @discovered_dispatcher}])
    end

    def executable
      File.basename($0)
    end
  end
end
