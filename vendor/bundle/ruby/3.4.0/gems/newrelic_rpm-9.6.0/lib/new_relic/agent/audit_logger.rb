# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'logger'
require 'fileutils'
require 'new_relic/agent/hostname'
require 'new_relic/agent/instrumentation/logger/instrumentation'

module NewRelic
  module Agent
    class AuditLogger
      def initialize
        @enabled = NewRelic::Agent.config[:'audit_log.enabled']
        @endpoints = NewRelic::Agent.config[:'audit_log.endpoints']
        @encoder = NewRelic::Agent::NewRelicService::Encoders::Identity
        @log = nil
      end

      attr_writer :enabled

      def enabled?
        @enabled
      end

      def setup?
        !@log.nil?
      end

      def log_request_headers(uri, headers)
        return unless enabled? && allowed_endpoint?(uri)

        @log.info("REQUEST HEADERS: #{headers}")
      rescue StandardError, SystemStackError, SystemCallError => e
        ::NewRelic::Agent.logger.warn('Failed writing request headers to audit log', e)
      rescue Exception => e
        ::NewRelic::Agent.logger.warn('Failed writing request headers to audit log with exception. Re-raising in case of interrupt.', e)
        raise
      end

      def log_request(uri, data, marshaller)
        return unless enabled? && allowed_endpoint?(uri)

        setup_logger unless setup?
        request_body = if marshaller.class.human_readable?
          marshaller.dump(data, :encoder => @encoder)
        else
          marshaller.prepare(data, :encoder => @encoder).inspect
        end
        @log.info("REQUEST: #{uri}")
        @log.info("REQUEST BODY: #{request_body}")
      rescue StandardError, SystemStackError, SystemCallError => e
        ::NewRelic::Agent.logger.warn('Failed writing to audit log', e)
      rescue Exception => e
        ::NewRelic::Agent.logger.warn('Failed writing to audit log with exception. Re-raising in case of interrupt.', e)
        raise
      end

      def allowed_endpoint?(uri)
        @endpoints.any? { |endpoint| uri =~ endpoint }
      end

      def setup_logger
        if wants_stdout?
          # Using $stdout global for easier reassignment in testing
          @log = ::Logger.new($stdout)
          ::NewRelic::Agent.logger.info('Audit log enabled to STDOUT')
        elsif path = ensure_log_path
          @log = ::Logger.new(path)
          ::NewRelic::Agent.logger.info("Audit log enabled at '#{path}'")
        else
          @log = NewRelic::Agent::NullLogger.new
        end

        # Never have agent log forwarding capture audits
        NewRelic::Agent::Instrumentation::Logger.mark_skip_instrumenting(@log)

        @log.formatter = create_log_formatter
      end

      def ensure_log_path
        path = File.expand_path(NewRelic::Agent.config[:'audit_log.path'])
        log_dir = File.dirname(path)

        begin
          FileUtils.mkdir_p(log_dir)
          FileUtils.touch(path)
        rescue SystemCallError => e
          msg = "Audit log disabled, failed opening log at '#{path}': #{e}"
          ::NewRelic::Agent.logger.warn(msg)
          path = nil
        end

        path
      end

      def wants_stdout?
        ::NewRelic::Agent.config[:'audit_log.path'].casecmp(NewRelic::STANDARD_OUT) == 0
      end

      def create_log_formatter
        @hostname = NewRelic::Agent::Hostname.get
        @prefix = wants_stdout? ? '** [NewRelic]' : ''
        proc do |severity, time, progname, msg|
          "#{@prefix}[#{time} #{@hostname} (#{$$})] : #{msg}\n"
        end
      end
    end
  end
end
