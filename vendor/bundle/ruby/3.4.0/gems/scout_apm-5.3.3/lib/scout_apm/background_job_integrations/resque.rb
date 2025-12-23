module ScoutApm
  module BackgroundJobIntegrations
    class Resque
      def name
        :resque
      end

      def present?
        defined?(::Resque) &&
          ::Resque.respond_to?(:before_first_fork) &&
          ::Resque.respond_to?(:after_fork)
      end

      # Lies. This forks really aggressively, but we have to do handling
      # of it manually here, rather than via any sort of automatic
      # background worker starting
      def forking?
        false
      end

      def install
        install_before_fork
        install_after_fork
      end

      def install_before_fork
        ::Resque.before_first_fork do
          begin
            if ScoutApm::Agent.instance.context.config.value('start_resque_server_instrument')
              ScoutApm::Agent.instance.start
              ScoutApm::Agent.instance.context.start_remote_server!(bind, port)
            else
              logger.info("Not starting remote server due to 'start_resque_server_instrument' setting")
            end
          rescue Errno::EADDRINUSE
            ScoutApm::Agent.instance.context.logger.warn "Error while Installing Resque Instruments, Port #{port} already in use. Set via the `remote_agent_port` configuration option"
          rescue => e
            ScoutApm::Agent.instance.context.logger.warn "Error while Installing Resque before_first_fork: #{e.inspect}"
          end
        end
      end

      def install_after_fork
        ::Resque.after_fork do
          begin
            ScoutApm::Agent.instance.context.become_remote_client!(bind, port)
            inject_job_instrument
          rescue => e
            ScoutApm::Agent.instance.context.logger.warn "Error while Installing Resque after_fork: #{e.inspect}"
          end
        end
      end

      # Insert ourselves into the point when resque turns a string "TestJob"
      # into the class constant TestJob, and insert our instrumentation plugin
      # into that constantized class
      #
      # This automates away any need for the user to insert our instrumentation into
      # each of their jobs
      def inject_job_instrument
        ::Resque::Job.class_eval do
          def payload_class_with_scout_instruments
            klass = payload_class_without_scout_instruments
            klass.extend(ScoutApm::Instruments::Resque)
            klass
          end
          alias_method :payload_class_without_scout_instruments, :payload_class
          alias_method :payload_class, :payload_class_with_scout_instruments
        end
      end

      private

      def bind
        config.value("remote_agent_host")
      end

      def port
        config.value("remote_agent_port")
      end

      def config
        @config || ScoutApm::Agent.instance.context.config
      end
    end
  end
end

