# frozen_string_literal: true

require "sidekiq/manager"
require "sidekiq/capsule"
require "sidekiq/scheduled"
require "sidekiq/ring_buffer"

module Sidekiq
  # The Launcher starts the Capsule Managers, the Poller thread and provides the process heartbeat.
  class Launcher
    include Sidekiq::Component

    STATS_TTL = 5 * 365 * 24 * 60 * 60 # 5 years

    PROCTITLES = [
      proc { "sidekiq" },
      proc { Sidekiq::VERSION },
      proc { |me, data| data["tag"] },
      proc { |me, data| "[#{Processor::WORK_STATE.size} of #{me.config.total_concurrency} busy]" },
      proc { |me, data| "stopping" if me.stopping? }
    ]

    attr_accessor :managers, :poller

    def initialize(config, embedded: false)
      @config = config
      @embedded = embedded
      @managers = config.capsules.values.map do |cap|
        Sidekiq::Manager.new(cap)
      end
      @poller = Sidekiq::Scheduled::Poller.new(@config)
      @done = false
    end

    # Start this Sidekiq instance. If an embedding process already
    # has a heartbeat thread, caller can use `async_beat: false`
    # and instead have thread call Launcher#heartbeat every N seconds.
    def run(async_beat: true)
      Sidekiq.freeze!
      logger.debug { @config.merge!({}) }
      @thread = safe_thread("heartbeat", &method(:start_heartbeat)) if async_beat
      @poller.start
      @managers.each(&:start)
    end

    # Stops this instance from processing any more jobs,
    def quiet
      return if @done

      @done = true
      @managers.each(&:quiet)
      @poller.terminate
      fire_event(:quiet, reverse: true)
    end

    # Shuts down this Sidekiq instance. Waits up to the deadline for all jobs to complete.
    def stop
      deadline = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) + @config[:timeout]

      quiet
      stoppers = @managers.map do |mgr|
        Thread.new do
          mgr.stop(deadline)
        end
      end

      fire_event(:shutdown, reverse: true)
      stoppers.each(&:join)

      clear_heartbeat
    end

    def stopping?
      @done
    end

    # If embedding Sidekiq, you can have the process heartbeat
    # call this method to regularly heartbeat rather than creating
    # a separate thread.
    def heartbeat
      ❤
    end

    private unless $TESTING

    BEAT_PAUSE = 10

    def start_heartbeat
      loop do
        beat
        sleep BEAT_PAUSE
      end
      logger.info("Heartbeat stopping...")
    end

    def beat
      $0 = PROCTITLES.map { |proc| proc.call(self, to_data) }.compact.join(" ") unless @embedded
      ❤
    end

    def clear_heartbeat
      flush_stats

      # Remove record from Redis since we are shutting down.
      # Note we don't stop the heartbeat thread; if the process
      # doesn't actually exit, it'll reappear in the Web UI.
      redis do |conn|
        conn.pipelined do |pipeline|
          pipeline.srem("processes", [identity])
          pipeline.unlink("#{identity}:work")
        end
      end
    rescue
      # best effort, ignore network errors
    end

    def flush_stats
      fails = Processor::FAILURE.reset
      procd = Processor::PROCESSED.reset
      return if fails + procd == 0

      nowdate = Time.now.utc.strftime("%Y-%m-%d")
      begin
        redis do |conn|
          conn.pipelined do |pipeline|
            pipeline.incrby("stat:processed", procd)
            pipeline.incrby("stat:processed:#{nowdate}", procd)
            pipeline.expire("stat:processed:#{nowdate}", STATS_TTL)

            pipeline.incrby("stat:failed", fails)
            pipeline.incrby("stat:failed:#{nowdate}", fails)
            pipeline.expire("stat:failed:#{nowdate}", STATS_TTL)
          end
        end
      rescue => ex
        logger.warn("Unable to flush stats: #{ex}")
      end
    end

    def ❤
      key = identity
      fails = procd = 0

      begin
        flush_stats

        curstate = Processor::WORK_STATE.dup
        curstate.transform_values! { |val| Sidekiq.dump_json(val) }

        redis do |conn|
          # work is the current set of executing jobs
          work_key = "#{key}:work"
          conn.multi do |transaction|
            transaction.unlink(work_key)
            if curstate.size > 0
              transaction.hset(work_key, curstate)
              transaction.expire(work_key, 60)
            end
          end
        end

        rtt = check_rtt

        fails = procd = 0
        kb = memory_usage(::Process.pid)

        _, exists, _, _, signal = redis { |conn|
          conn.multi { |transaction|
            transaction.sadd("processes", [key])
            transaction.exists(key)
            transaction.hset(key, "info", to_json,
              "busy", curstate.size,
              "beat", Time.now.to_f,
              "rtt_us", rtt,
              "quiet", @done.to_s,
              "rss", kb)
            transaction.expire(key, 60)
            transaction.rpop("#{key}-signals")
          }
        }

        # first heartbeat or recovering from an outage and need to reestablish our heartbeat
        fire_event(:heartbeat) unless exists > 0
        fire_event(:beat, oneshot: false)

        ::Process.kill(signal, ::Process.pid) if signal && !@embedded
      rescue => e
        # ignore all redis/network issues
        logger.error("heartbeat: #{e}")
        # don't lose the counts if there was a network issue
        Processor::PROCESSED.incr(procd)
        Processor::FAILURE.incr(fails)
      end
    end

    # We run the heartbeat every five seconds.
    # Capture five samples of RTT, log a warning if each sample
    # is above our warning threshold.
    RTT_READINGS = RingBuffer.new(5)
    RTT_WARNING_LEVEL = 50_000

    def check_rtt
      a = b = 0
      redis do |x|
        a = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :microsecond)
        x.ping
        b = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC, :microsecond)
      end
      rtt = b - a
      RTT_READINGS << rtt
      # Ideal RTT for Redis is < 1000µs
      # Workable is < 10,000µs
      # Log a warning if it's a disaster.
      if RTT_READINGS.all? { |x| x > RTT_WARNING_LEVEL }
        logger.warn <<~EOM
          Your Redis network connection is performing extremely poorly.
          Last RTT readings were #{RTT_READINGS.buffer.inspect}, ideally these should be < 1000.
          Ensure Redis is running in the same AZ or datacenter as Sidekiq.
          If these values are close to 100,000, that means your Sidekiq process may be
          CPU-saturated; reduce your concurrency and/or see https://github.com/sidekiq/sidekiq/discussions/5039
        EOM
        RTT_READINGS.reset
      end
      rtt
    end

    MEMORY_GRABBER = case RUBY_PLATFORM
    when /linux/
      ->(pid) {
        IO.readlines("/proc/#{$$}/status").each do |line|
          next unless line.start_with?("VmRSS:")
          break line.split[1].to_i
        end
      }
    when /darwin|bsd/
      ->(pid) {
        `ps -o pid,rss -p #{pid}`.lines.last.split.last.to_i
      }
    else
      ->(pid) { 0 }
    end

    def memory_usage(pid)
      MEMORY_GRABBER.call(pid)
    end

    def to_data
      @data ||= {
        "hostname" => hostname,
        "started_at" => Time.now.to_f,
        "pid" => ::Process.pid,
        "tag" => @config[:tag] || "",
        "concurrency" => @config.total_concurrency,
        "queues" => @config.capsules.values.flat_map { |cap| cap.queues }.uniq,
        "weights" => to_weights,
        "labels" => @config[:labels].to_a,
        "identity" => identity,
        "version" => Sidekiq::VERSION,
        "embedded" => @embedded
      }
    end

    def to_weights
      @config.capsules.values.map(&:weights)
    end

    def to_json
      # this data changes infrequently so dump it to a string
      # now so we don't need to dump it every heartbeat.
      @json ||= Sidekiq.dump_json(to_data)
    end
  end
end
