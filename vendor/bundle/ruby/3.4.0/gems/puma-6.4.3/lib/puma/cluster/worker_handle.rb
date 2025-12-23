# frozen_string_literal: true

module Puma
  class Cluster < Runner
    #—————————————————————— DO NOT USE — this class is for internal use only ———


    # This class represents a worker process from the perspective of the puma
    # master process. It contains information about the process and its health
    # and it exposes methods to control the process via IPC. It does not
    # include the actual logic executed by the worker process itself. For that,
    # see Puma::Cluster::Worker.
    class WorkerHandle # :nodoc:
      def initialize(idx, pid, phase, options)
        @index = idx
        @pid = pid
        @phase = phase
        @stage = :started
        @signal = "TERM"
        @options = options
        @first_term_sent = nil
        @started_at = Time.now
        @last_checkin = Time.now
        @last_status = {}
        @term = false
      end

      attr_reader :index, :pid, :phase, :signal, :last_checkin, :last_status, :started_at

      # @version 5.0.0
      attr_writer :pid, :phase

      def booted?
        @stage == :booted
      end

      def uptime
        Time.now - started_at
      end

      def boot!
        @last_checkin = Time.now
        @stage = :booted
      end

      def term!
        @term = true
      end

      def term?
        @term
      end

      def ping!(status)
        @last_checkin = Time.now
        captures = status.match(/{ "backlog":(?<backlog>\d*), "running":(?<running>\d*), "pool_capacity":(?<pool_capacity>\d*), "max_threads": (?<max_threads>\d*), "requests_count": (?<requests_count>\d*) }/)
        @last_status = captures.names.inject({}) do |hash, key|
          hash[key.to_sym] = captures[key].to_i
          hash
        end
      end

      # @see Puma::Cluster#check_workers
      # @version 5.0.0
      def ping_timeout
        @last_checkin +
          (booted? ?
            @options[:worker_timeout] :
            @options[:worker_boot_timeout]
          )
      end

      def term
        begin
          if @first_term_sent && (Time.now - @first_term_sent) > @options[:worker_shutdown_timeout]
            @signal = "KILL"
          else
            @term ||= true
            @first_term_sent ||= Time.now
          end
          Process.kill @signal, @pid if @pid
        rescue Errno::ESRCH
        end
      end

      def kill
        @signal = 'KILL'
        term
      end

      def hup
        Process.kill "HUP", @pid
      rescue Errno::ESRCH
      end
    end
  end
end
