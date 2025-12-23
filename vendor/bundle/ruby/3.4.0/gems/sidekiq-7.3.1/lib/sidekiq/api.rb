# frozen_string_literal: true

require "sidekiq"

require "zlib"
require "set"

require "sidekiq/metrics/query"

#
# Sidekiq's Data API provides a Ruby object model on top
# of Sidekiq's runtime data in Redis. This API should never
# be used within application code for business logic.
#
# The Sidekiq server process never uses this API: all data
# manipulation is done directly for performance reasons to
# ensure we are using Redis as efficiently as possible at
# every callsite.
#

module Sidekiq
  # Retrieve runtime statistics from Redis regarding
  # this Sidekiq cluster.
  #
  #   stat = Sidekiq::Stats.new
  #   stat.processed
  class Stats
    def initialize
      fetch_stats_fast!
    end

    def processed
      stat :processed
    end

    def failed
      stat :failed
    end

    def scheduled_size
      stat :scheduled_size
    end

    def retry_size
      stat :retry_size
    end

    def dead_size
      stat :dead_size
    end

    def enqueued
      stat :enqueued
    end

    def processes_size
      stat :processes_size
    end

    def workers_size
      stat :workers_size
    end

    def default_queue_latency
      stat :default_queue_latency
    end

    def queues
      Sidekiq.redis do |conn|
        queues = conn.sscan("queues").to_a

        lengths = conn.pipelined { |pipeline|
          queues.each do |queue|
            pipeline.llen("queue:#{queue}")
          end
        }

        array_of_arrays = queues.zip(lengths).sort_by { |_, size| -size }
        array_of_arrays.to_h
      end
    end

    # O(1) redis calls
    # @api private
    def fetch_stats_fast!
      pipe1_res = Sidekiq.redis { |conn|
        conn.pipelined do |pipeline|
          pipeline.get("stat:processed")
          pipeline.get("stat:failed")
          pipeline.zcard("schedule")
          pipeline.zcard("retry")
          pipeline.zcard("dead")
          pipeline.scard("processes")
          pipeline.lindex("queue:default", -1)
        end
      }

      default_queue_latency = if (entry = pipe1_res[6])
        job = begin
          Sidekiq.load_json(entry)
        rescue
          {}
        end
        now = Time.now.to_f
        thence = job["enqueued_at"] || now
        now - thence
      else
        0
      end

      @stats = {
        processed: pipe1_res[0].to_i,
        failed: pipe1_res[1].to_i,
        scheduled_size: pipe1_res[2],
        retry_size: pipe1_res[3],
        dead_size: pipe1_res[4],
        processes_size: pipe1_res[5],

        default_queue_latency: default_queue_latency
      }
    end

    # O(number of processes + number of queues) redis calls
    # @api private
    def fetch_stats_slow!
      processes = Sidekiq.redis { |conn|
        conn.sscan("processes").to_a
      }

      queues = Sidekiq.redis { |conn|
        conn.sscan("queues").to_a
      }

      pipe2_res = Sidekiq.redis { |conn|
        conn.pipelined do |pipeline|
          processes.each { |key| pipeline.hget(key, "busy") }
          queues.each { |queue| pipeline.llen("queue:#{queue}") }
        end
      }

      s = processes.size
      workers_size = pipe2_res[0...s].sum(&:to_i)
      enqueued = pipe2_res[s..].sum(&:to_i)

      @stats[:workers_size] = workers_size
      @stats[:enqueued] = enqueued
      @stats
    end

    # @api private
    def fetch_stats!
      fetch_stats_fast!
      fetch_stats_slow!
    end

    # @api private
    def reset(*stats)
      all = %w[failed processed]
      stats = stats.empty? ? all : all & stats.flatten.compact.map(&:to_s)

      mset_args = []
      stats.each do |stat|
        mset_args << "stat:#{stat}"
        mset_args << 0
      end
      Sidekiq.redis do |conn|
        conn.mset(*mset_args)
      end
    end

    private

    def stat(s)
      fetch_stats_slow! if @stats[s].nil?
      @stats[s] || raise(ArgumentError, "Unknown stat #{s}")
    end

    class History
      def initialize(days_previous, start_date = nil, pool: nil)
        # we only store five years of data in Redis
        raise ArgumentError if days_previous < 1 || days_previous > (5 * 365)
        @days_previous = days_previous
        @start_date = start_date || Time.now.utc.to_date
      end

      def processed
        @processed ||= date_stat_hash("processed")
      end

      def failed
        @failed ||= date_stat_hash("failed")
      end

      private

      def date_stat_hash(stat)
        stat_hash = {}
        dates = @start_date.downto(@start_date - @days_previous + 1).map { |date|
          date.strftime("%Y-%m-%d")
        }

        keys = dates.map { |datestr| "stat:#{stat}:#{datestr}" }

        Sidekiq.redis do |conn|
          conn.mget(keys).each_with_index do |value, idx|
            stat_hash[dates[idx]] = value ? value.to_i : 0
          end
        end

        stat_hash
      end
    end
  end

  ##
  # Represents a queue within Sidekiq.
  # Allows enumeration of all jobs within the queue
  # and deletion of jobs. NB: this queue data is real-time
  # and is changing within Redis moment by moment.
  #
  #   queue = Sidekiq::Queue.new("mailer")
  #   queue.each do |job|
  #     job.klass # => 'MyWorker'
  #     job.args # => [1, 2, 3]
  #     job.delete if job.jid == 'abcdef1234567890'
  #   end
  class Queue
    include Enumerable

    ##
    # Fetch all known queues within Redis.
    #
    # @return [Array<Sidekiq::Queue>]
    def self.all
      Sidekiq.redis { |c| c.sscan("queues").to_a }.sort.map { |q| Sidekiq::Queue.new(q) }
    end

    attr_reader :name

    # @param name [String] the name of the queue
    def initialize(name = "default")
      @name = name.to_s
      @rname = "queue:#{name}"
    end

    # The current size of the queue within Redis.
    # This value is real-time and can change between calls.
    #
    # @return [Integer] the size
    def size
      Sidekiq.redis { |con| con.llen(@rname) }
    end

    # @return [Boolean] if the queue is currently paused
    def paused?
      false
    end

    ##
    # Calculates this queue's latency, the difference in seconds since the oldest
    # job in the queue was enqueued.
    #
    # @return [Float] in seconds
    def latency
      entry = Sidekiq.redis { |conn|
        conn.lindex(@rname, -1)
      }
      return 0 unless entry
      job = Sidekiq.load_json(entry)
      now = Time.now.to_f
      thence = job["enqueued_at"] || now
      now - thence
    end

    def each
      initial_size = size
      deleted_size = 0
      page = 0
      page_size = 50

      loop do
        range_start = page * page_size - deleted_size
        range_end = range_start + page_size - 1
        entries = Sidekiq.redis { |conn|
          conn.lrange @rname, range_start, range_end
        }
        break if entries.empty?
        page += 1
        entries.each do |entry|
          yield JobRecord.new(entry, @name)
        end
        deleted_size = initial_size - size
      end
    end

    ##
    # Find the job with the given JID within this queue.
    #
    # This is a *slow, inefficient* operation.  Do not use under
    # normal conditions.
    #
    # @param jid [String] the job_id to look for
    # @return [Sidekiq::JobRecord]
    # @return [nil] if not found
    def find_job(jid)
      detect { |j| j.jid == jid }
    end

    # delete all jobs within this queue
    # @return [Boolean] true
    def clear
      Sidekiq.redis do |conn|
        conn.multi do |transaction|
          transaction.unlink(@rname)
          transaction.srem("queues", [name])
        end
      end
      true
    end
    alias_method :💣, :clear

    # :nodoc:
    # @api private
    def as_json(options = nil)
      {name: name} # 5336
    end
  end

  ##
  # Represents a pending job within a Sidekiq queue.
  #
  # The job should be considered immutable but may be
  # removed from the queue via JobRecord#delete.
  class JobRecord
    # the parsed Hash of job data
    # @!attribute [r] Item
    attr_reader :item
    # the underlying String in Redis
    # @!attribute [r] Value
    attr_reader :value
    # the queue associated with this job
    # @!attribute [r] Queue
    attr_reader :queue

    # :nodoc:
    # @api private
    def initialize(item, queue_name = nil)
      @args = nil
      @value = item
      @item = item.is_a?(Hash) ? item : parse(item)
      @queue = queue_name || @item["queue"]
    end

    # :nodoc:
    # @api private
    def parse(item)
      Sidekiq.load_json(item)
    rescue JSON::ParserError
      # If the job payload in Redis is invalid JSON, we'll load
      # the item as an empty hash and store the invalid JSON as
      # the job 'args' for display in the Web UI.
      @invalid = true
      @args = [item]
      {}
    end

    # This is the job class which Sidekiq will execute. If using ActiveJob,
    # this class will be the ActiveJob adapter class rather than a specific job.
    def klass
      self["class"]
    end

    def display_class
      # Unwrap known wrappers so they show up in a human-friendly manner in the Web UI
      @klass ||= self["display_class"] || begin
        if klass == "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
          job_class = @item["wrapped"] || args[0]
          if job_class == "ActionMailer::DeliveryJob" || job_class == "ActionMailer::MailDeliveryJob"
            # MailerClass#mailer_method
            args[0]["arguments"][0..1].join("#")
          else
            job_class
          end
        else
          klass
        end
      end
    end

    def display_args
      # Unwrap known wrappers so they show up in a human-friendly manner in the Web UI
      @display_args ||= if klass == "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper"
        job_args = self["wrapped"] ? deserialize_argument(args[0]["arguments"]) : []
        if (self["wrapped"] || args[0]) == "ActionMailer::DeliveryJob"
          # remove MailerClass, mailer_method and 'deliver_now'
          job_args.drop(3)
        elsif (self["wrapped"] || args[0]) == "ActionMailer::MailDeliveryJob"
          # remove MailerClass, mailer_method and 'deliver_now'
          job_args.drop(3).first.values_at("params", "args")
        else
          job_args
        end
      else
        if self["encrypt"]
          # no point in showing 150+ bytes of random garbage
          args[-1] = "[encrypted data]"
        end
        args
      end
    end

    def args
      @args || @item["args"]
    end

    def jid
      self["jid"]
    end

    def bid
      self["bid"]
    end

    def enqueued_at
      self["enqueued_at"] ? Time.at(self["enqueued_at"]).utc : nil
    end

    def created_at
      Time.at(self["created_at"] || self["enqueued_at"] || 0).utc
    end

    def tags
      self["tags"] || []
    end

    def error_backtrace
      # Cache nil values
      if defined?(@error_backtrace)
        @error_backtrace
      else
        value = self["error_backtrace"]
        @error_backtrace = value && uncompress_backtrace(value)
      end
    end

    def latency
      now = Time.now.to_f
      now - (@item["enqueued_at"] || @item["created_at"] || now)
    end

    # Remove this job from the queue
    def delete
      count = Sidekiq.redis { |conn|
        conn.lrem("queue:#{@queue}", 1, @value)
      }
      count != 0
    end

    # Access arbitrary attributes within the job hash
    def [](name)
      # nil will happen if the JSON fails to parse.
      # We don't guarantee Sidekiq will work with bad job JSON but we should
      # make a best effort to minimize the damage.
      @item ? @item[name] : nil
    end

    private

    ACTIVE_JOB_PREFIX = "_aj_"
    GLOBALID_KEY = "_aj_globalid"

    def deserialize_argument(argument)
      case argument
      when Array
        argument.map { |arg| deserialize_argument(arg) }
      when Hash
        if serialized_global_id?(argument)
          argument[GLOBALID_KEY]
        else
          argument.transform_values { |v| deserialize_argument(v) }
            .reject { |k, _| k.start_with?(ACTIVE_JOB_PREFIX) }
        end
      else
        argument
      end
    end

    def serialized_global_id?(hash)
      hash.size == 1 && hash.include?(GLOBALID_KEY)
    end

    def uncompress_backtrace(backtrace)
      strict_base64_decoded = backtrace.unpack1("m")
      uncompressed = Zlib::Inflate.inflate(strict_base64_decoded)
      Sidekiq.load_json(uncompressed)
    end
  end

  # Represents a job within a Redis sorted set where the score
  # represents a timestamp associated with the job. This timestamp
  # could be the scheduled time for it to run (e.g. scheduled set),
  # or the expiration date after which the entry should be deleted (e.g. dead set).
  class SortedEntry < JobRecord
    attr_reader :score
    attr_reader :parent

    # :nodoc:
    # @api private
    def initialize(parent, score, item)
      super(item)
      @score = Float(score)
      @parent = parent
    end

    # The timestamp associated with this entry
    def at
      Time.at(score).utc
    end

    # remove this entry from the sorted set
    def delete
      if @value
        @parent.delete_by_value(@parent.name, @value)
      else
        @parent.delete_by_jid(score, jid)
      end
    end

    # Change the scheduled time for this job.
    #
    # @param at [Time] the new timestamp for this job
    def reschedule(at)
      Sidekiq.redis do |conn|
        conn.zincrby(@parent.name, at.to_f - @score, Sidekiq.dump_json(@item))
      end
    end

    # Enqueue this job from the scheduled or dead set so it will
    # be executed at some point in the near future.
    def add_to_queue
      remove_job do |message|
        msg = Sidekiq.load_json(message)
        Sidekiq::Client.push(msg)
      end
    end

    # enqueue this job from the retry set so it will be executed
    # at some point in the near future.
    def retry
      remove_job do |message|
        msg = Sidekiq.load_json(message)
        msg["retry_count"] -= 1 if msg["retry_count"]
        Sidekiq::Client.push(msg)
      end
    end

    # Move this job from its current set into the Dead set.
    def kill
      remove_job do |message|
        DeadSet.new.kill(message)
      end
    end

    def error?
      !!item["error_class"]
    end

    private

    def remove_job
      Sidekiq.redis do |conn|
        results = conn.multi { |transaction|
          transaction.zrange(parent.name, score, score, "BYSCORE")
          transaction.zremrangebyscore(parent.name, score, score)
        }.first

        if results.size == 1
          yield results.first
        else
          # multiple jobs with the same score
          # find the one with the right JID and push it
          matched, nonmatched = results.partition { |message|
            if message.index(jid)
              msg = Sidekiq.load_json(message)
              msg["jid"] == jid
            else
              false
            end
          }

          msg = matched.first
          yield msg if msg

          # push the rest back onto the sorted set
          conn.multi do |transaction|
            nonmatched.each do |message|
              transaction.zadd(parent.name, score.to_f.to_s, message)
            end
          end
        end
      end
    end
  end

  # Base class for all sorted sets within Sidekiq.
  class SortedSet
    include Enumerable

    # Redis key of the set
    # @!attribute [r] Name
    attr_reader :name

    # :nodoc:
    # @api private
    def initialize(name)
      @name = name
      @_size = size
    end

    # real-time size of the set, will change
    def size
      Sidekiq.redis { |c| c.zcard(name) }
    end

    # Scan through each element of the sorted set, yielding each to the supplied block.
    # Please see Redis's <a href="https://redis.io/commands/scan/">SCAN documentation</a> for implementation details.
    #
    # @param match [String] a snippet or regexp to filter matches.
    # @param count [Integer] number of elements to retrieve at a time, default 100
    # @yieldparam [Sidekiq::SortedEntry] each entry
    def scan(match, count = 100)
      return to_enum(:scan, match, count) unless block_given?

      match = "*#{match}*" unless match.include?("*")
      Sidekiq.redis do |conn|
        conn.zscan(name, match: match, count: count) do |entry, score|
          yield SortedEntry.new(self, score, entry)
        end
      end
    end

    # @return [Boolean] always true
    def clear
      Sidekiq.redis do |conn|
        conn.unlink(name)
      end
      true
    end
    alias_method :💣, :clear

    # :nodoc:
    # @api private
    def as_json(options = nil)
      {name: name} # 5336
    end
  end

  # Base class for all sorted sets which contain jobs, e.g. scheduled, retry and dead.
  # Sidekiq Pro and Enterprise add additional sorted sets which do not contain job data,
  # e.g. Batches.
  class JobSet < SortedSet
    # Add a job with the associated timestamp to this set.
    # @param timestamp [Time] the score for the job
    # @param job [Hash] the job data
    def schedule(timestamp, job)
      Sidekiq.redis do |conn|
        conn.zadd(name, timestamp.to_f.to_s, Sidekiq.dump_json(job))
      end
    end

    def each
      initial_size = @_size
      offset_size = 0
      page = -1
      page_size = 50

      loop do
        range_start = page * page_size + offset_size
        range_end = range_start + page_size - 1
        elements = Sidekiq.redis { |conn|
          conn.zrange name, range_start, range_end, "withscores"
        }
        break if elements.empty?
        page -= 1
        elements.reverse_each do |element, score|
          yield SortedEntry.new(self, score, element)
        end
        offset_size = initial_size - @_size
      end
    end

    ##
    # Fetch jobs that match a given time or Range. Job ID is an
    # optional second argument.
    #
    # @param score [Time,Range] a specific timestamp or range
    # @param jid [String, optional] find a specific JID within the score
    # @return [Array<SortedEntry>] any results found, can be empty
    def fetch(score, jid = nil)
      begin_score, end_score =
        if score.is_a?(Range)
          [score.first, score.last]
        else
          [score, score]
        end

      elements = Sidekiq.redis { |conn|
        conn.zrange(name, begin_score, end_score, "BYSCORE", "withscores")
      }

      elements.each_with_object([]) do |element, result|
        data, job_score = element
        entry = SortedEntry.new(self, job_score, data)
        result << entry if jid.nil? || entry.jid == jid
      end
    end

    ##
    # Find the job with the given JID within this sorted set.
    # *This is a slow O(n) operation*.  Do not use for app logic.
    #
    # @param jid [String] the job identifier
    # @return [SortedEntry] the record or nil
    def find_job(jid)
      Sidekiq.redis do |conn|
        conn.zscan(name, match: "*#{jid}*", count: 100) do |entry, score|
          job = Sidekiq.load_json(entry)
          matched = job["jid"] == jid
          return SortedEntry.new(self, score, entry) if matched
        end
      end
      nil
    end

    # :nodoc:
    # @api private
    def delete_by_value(name, value)
      Sidekiq.redis do |conn|
        ret = conn.zrem(name, value)
        @_size -= 1 if ret
        ret
      end
    end

    # :nodoc:
    # @api private
    def delete_by_jid(score, jid)
      Sidekiq.redis do |conn|
        elements = conn.zrange(name, score, score, "BYSCORE")
        elements.each do |element|
          if element.index(jid)
            message = Sidekiq.load_json(element)
            if message["jid"] == jid
              ret = conn.zrem(name, element)
              @_size -= 1 if ret
              break ret
            end
          end
        end
      end
    end

    alias_method :delete, :delete_by_jid
  end

  ##
  # The set of scheduled jobs within Sidekiq.
  # Based on this, you can search/filter for jobs.  Here's an
  # example where I'm selecting jobs based on some complex logic
  # and deleting them from the scheduled set.
  #
  # See the API wiki page for usage notes and examples.
  #
  class ScheduledSet < JobSet
    def initialize
      super("schedule")
    end
  end

  ##
  # The set of retries within Sidekiq.
  # Based on this, you can search/filter for jobs.  Here's an
  # example where I'm selecting all jobs of a certain type
  # and deleting them from the retry queue.
  #
  # See the API wiki page for usage notes and examples.
  #
  class RetrySet < JobSet
    def initialize
      super("retry")
    end

    # Enqueues all jobs pending within the retry set.
    def retry_all
      each(&:retry) while size > 0
    end

    # Kills all jobs pending within the retry set.
    def kill_all
      each(&:kill) while size > 0
    end
  end

  ##
  # The set of dead jobs within Sidekiq. Dead jobs have failed all of
  # their retries and are helding in this set pending some sort of manual
  # fix. They will be removed after 6 months (dead_timeout) if not.
  #
  class DeadSet < JobSet
    def initialize
      super("dead")
    end

    # Add the given job to the Dead set.
    # @param message [String] the job data as JSON
    # @option opts :notify_failure [Boolean] (true) Whether death handlers should be called
    # @option opts :ex [Exception] (RuntimeError) An exception to pass to the death handlers
    def kill(message, opts = {})
      now = Time.now.to_f
      Sidekiq.redis do |conn|
        conn.multi do |transaction|
          transaction.zadd(name, now.to_s, message)
          transaction.zremrangebyscore(name, "-inf", now - Sidekiq::Config::DEFAULTS[:dead_timeout_in_seconds])
          transaction.zremrangebyrank(name, 0, - Sidekiq::Config::DEFAULTS[:dead_max_jobs])
        end
      end

      if opts[:notify_failure] != false
        job = Sidekiq.load_json(message)
        if opts[:ex]
          ex = opt[:ex]
        else
          ex = RuntimeError.new("Job killed by API")
          ex.set_backtrace(caller)
        end
        Sidekiq.default_configuration.death_handlers.each do |handle|
          handle.call(job, ex)
        end
      end
      true
    end

    # Enqueue all dead jobs
    def retry_all
      each(&:retry) while size > 0
    end
  end

  ##
  # Enumerates the set of Sidekiq processes which are actively working
  # right now.  Each process sends a heartbeat to Redis every 5 seconds
  # so this set should be relatively accurate, barring network partitions.
  #
  # @yieldparam [Sidekiq::Process]
  #
  class ProcessSet
    include Enumerable

    def self.[](identity)
      exists, (info, busy, beat, quiet, rss, rtt_us) = Sidekiq.redis { |conn|
        conn.multi { |transaction|
          transaction.sismember("processes", identity)
          transaction.hmget(identity, "info", "busy", "beat", "quiet", "rss", "rtt_us")
        }
      }

      return nil if exists == 0 || info.nil?

      hash = Sidekiq.load_json(info)
      Process.new(hash.merge("busy" => busy.to_i,
        "beat" => beat.to_f,
        "quiet" => quiet,
        "rss" => rss.to_i,
        "rtt_us" => rtt_us.to_i))
    end

    # :nodoc:
    # @api private
    def initialize(clean_plz = true)
      cleanup if clean_plz
    end

    # Cleans up dead processes recorded in Redis.
    # Returns the number of processes cleaned.
    # :nodoc:
    # @api private
    def cleanup
      # dont run cleanup more than once per minute
      return 0 unless Sidekiq.redis { |conn| conn.set("process_cleanup", "1", "NX", "EX", "60") }

      count = 0
      Sidekiq.redis do |conn|
        procs = conn.sscan("processes").to_a
        heartbeats = conn.pipelined { |pipeline|
          procs.each do |key|
            pipeline.hget(key, "info")
          end
        }

        # the hash named key has an expiry of 60 seconds.
        # if it's not found, that means the process has not reported
        # in to Redis and probably died.
        to_prune = procs.select.with_index { |proc, i|
          heartbeats[i].nil?
        }
        count = conn.srem("processes", to_prune) unless to_prune.empty?
      end
      count
    end

    def each
      result = Sidekiq.redis { |conn|
        procs = conn.sscan("processes").to_a.sort

        # We're making a tradeoff here between consuming more memory instead of
        # making more roundtrips to Redis, but if you have hundreds or thousands of workers,
        # you'll be happier this way
        conn.pipelined do |pipeline|
          procs.each do |key|
            pipeline.hmget(key, "info", "busy", "beat", "quiet", "rss", "rtt_us")
          end
        end
      }

      result.each do |info, busy, beat, quiet, rss, rtt_us|
        # If a process is stopped between when we query Redis for `procs` and
        # when we query for `result`, we will have an item in `result` that is
        # composed of `nil` values.
        next if info.nil?

        hash = Sidekiq.load_json(info)
        yield Process.new(hash.merge("busy" => busy.to_i,
          "beat" => beat.to_f,
          "quiet" => quiet,
          "rss" => rss.to_i,
          "rtt_us" => rtt_us.to_i))
      end
    end

    # This method is not guaranteed accurate since it does not prune the set
    # based on current heartbeat.  #each does that and ensures the set only
    # contains Sidekiq processes which have sent a heartbeat within the last
    # 60 seconds.
    # @return [Integer] current number of registered Sidekiq processes
    def size
      Sidekiq.redis { |conn| conn.scard("processes") }
    end

    # Total number of threads available to execute jobs.
    # For Sidekiq Enterprise customers this number (in production) must be
    # less than or equal to your licensed concurrency.
    # @return [Integer] the sum of process concurrency
    def total_concurrency
      sum { |x| x["concurrency"].to_i }
    end

    # @return [Integer] total amount of RSS memory consumed by Sidekiq processes
    def total_rss_in_kb
      sum { |x| x["rss"].to_i }
    end
    alias_method :total_rss, :total_rss_in_kb

    # Returns the identity of the current cluster leader or "" if no leader.
    # This is a Sidekiq Enterprise feature, will always return "" in Sidekiq
    # or Sidekiq Pro.
    # @return [String] Identity of cluster leader
    # @return [String] empty string if no leader
    def leader
      @leader ||= begin
        x = Sidekiq.redis { |c| c.get("dear-leader") }
        # need a non-falsy value so we can memoize
        x ||= ""
        x
      end
    end
  end

  #
  # Sidekiq::Process represents an active Sidekiq process talking with Redis.
  # Each process has a set of attributes which look like this:
  #
  # {
  #   'hostname' => 'app-1.example.com',
  #   'started_at' => <process start time>,
  #   'pid' => 12345,
  #   'tag' => 'myapp'
  #   'concurrency' => 25,
  #   'queues' => ['default', 'low'],
  #   'busy' => 10,
  #   'beat' => <last heartbeat>,
  #   'identity' => <unique string identifying the process>,
  #   'embedded' => true,
  # }
  class Process
    # :nodoc:
    # @api private
    def initialize(hash)
      @attribs = hash
    end

    def tag
      self["tag"]
    end

    def labels
      self["labels"].to_a
    end

    def [](key)
      @attribs[key]
    end

    def identity
      self["identity"]
    end

    def queues
      self["queues"]
    end

    def weights
      self["weights"]
    end

    def version
      self["version"]
    end

    def embedded?
      self["embedded"]
    end

    # Signal this process to stop processing new jobs.
    # It will continue to execute jobs it has already fetched.
    # This method is *asynchronous* and it can take 5-10
    # seconds for the process to quiet.
    def quiet!
      raise "Can't quiet an embedded process" if embedded?

      signal("TSTP")
    end

    # Signal this process to shutdown.
    # It will shutdown within its configured :timeout value, default 25 seconds.
    # This method is *asynchronous* and it can take 5-10
    # seconds for the process to start shutting down.
    def stop!
      raise "Can't stop an embedded process" if embedded?

      signal("TERM")
    end

    # Signal this process to log backtraces for all threads.
    # Useful if you have a frozen or deadlocked process which is
    # still sending a heartbeat.
    # This method is *asynchronous* and it can take 5-10 seconds.
    def dump_threads
      signal("TTIN")
    end

    # @return [Boolean] true if this process is quiet or shutting down
    def stopping?
      self["quiet"] == "true"
    end

    private

    def signal(sig)
      key = "#{identity}-signals"
      Sidekiq.redis do |c|
        c.multi do |transaction|
          transaction.lpush(key, sig)
          transaction.expire(key, 60)
        end
      end
    end
  end

  ##
  # The WorkSet stores the work being done by this Sidekiq cluster.
  # It tracks the process and thread working on each job.
  #
  # WARNING WARNING WARNING
  #
  # This is live data that can change every millisecond.
  # If you call #size => 5 and then expect #each to be
  # called 5 times, you're going to have a bad time.
  #
  #    works = Sidekiq::WorkSet.new
  #    works.size => 2
  #    works.each do |process_id, thread_id, work|
  #      # process_id is a unique identifier per Sidekiq process
  #      # thread_id is a unique identifier per thread
  #      # work is a Hash which looks like:
  #      # { 'queue' => name, 'run_at' => timestamp, 'payload' => job_hash }
  #      # run_at is an epoch Integer.
  #    end
  #
  class WorkSet
    include Enumerable

    def each(&block)
      results = []
      procs = nil
      all_works = nil

      Sidekiq.redis do |conn|
        procs = conn.sscan("processes").to_a.sort
        all_works = conn.pipelined do |pipeline|
          procs.each do |key|
            pipeline.hgetall("#{key}:work")
          end
        end
      end

      procs.zip(all_works).each do |key, workers|
        workers.each_pair do |tid, json|
          results << [key, tid, Sidekiq::Work.new(key, tid, Sidekiq.load_json(json))] unless json.empty?
        end
      end

      results.sort_by { |(_, _, hsh)| hsh.raw("run_at") }.each(&block)
    end

    # Note that #size is only as accurate as Sidekiq's heartbeat,
    # which happens every 5 seconds.  It is NOT real-time.
    #
    # Not very efficient if you have lots of Sidekiq
    # processes but the alternative is a global counter
    # which can easily get out of sync with crashy processes.
    def size
      Sidekiq.redis do |conn|
        procs = conn.sscan("processes").to_a
        if procs.empty?
          0
        else
          conn.pipelined { |pipeline|
            procs.each do |key|
              pipeline.hget(key, "busy")
            end
          }.sum(&:to_i)
        end
      end
    end

    ##
    # Find the work which represents a job with the given JID.
    # *This is a slow O(n) operation*.  Do not use for app logic.
    #
    # @param jid [String] the job identifier
    # @return [Sidekiq::Work] the work or nil
    def find_work_by_jid(jid)
      each do |_process_id, _thread_id, work|
        job = work.job
        return work if job.jid == jid
      end
      nil
    end
  end

  # Sidekiq::Work represents a job which is currently executing.
  class Work
    attr_reader :process_id
    attr_reader :thread_id

    def initialize(pid, tid, hsh)
      @process_id = pid
      @thread_id = tid
      @hsh = hsh
      @job = nil
    end

    def queue
      @hsh["queue"]
    end

    def run_at
      Time.at(@hsh["run_at"])
    end

    def job
      @job ||= Sidekiq::JobRecord.new(@hsh["payload"])
    end

    def payload
      @hsh["payload"]
    end

    # deprecated
    def [](key)
      kwargs = {uplevel: 1}
      kwargs[:category] = :deprecated if RUBY_VERSION > "3.0" # TODO
      warn("Direct access to `Sidekiq::Work` attributes is deprecated, please use `#payload`, `#queue`, `#run_at` or `#job` instead", **kwargs)

      @hsh[key]
    end

    # :nodoc:
    # @api private
    def raw(name)
      @hsh[name]
    end

    def method_missing(*all)
      @hsh.send(*all)
    end

    def respond_to_missing?(name, *args)
      @hsh.respond_to?(name)
    end
  end

  # Since "worker" is a nebulous term, we've deprecated the use of this class name.
  # Is "worker" a process, a type of job, a thread? Undefined!
  # WorkSet better describes the data.
  Workers = WorkSet
end
