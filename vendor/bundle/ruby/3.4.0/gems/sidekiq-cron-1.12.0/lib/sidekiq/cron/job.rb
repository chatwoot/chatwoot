require 'fugit'
require 'globalid'
require 'sidekiq'
require 'sidekiq/cron/support'
require 'sidekiq/options'

module Sidekiq
  module Cron
    class Job
      # How long we would like to store informations about previous enqueues.
      REMEMBER_THRESHOLD = 24 * 60 * 60

      # Time format for enqueued jobs.
      LAST_ENQUEUE_TIME_FORMAT = '%Y-%m-%d %H:%M:%S %z'

      # Use the exists? method if we're on a newer version of Redis.
      REDIS_EXISTS_METHOD = Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new("7.0.0") || Gem.loaded_specs['redis'].version < Gem::Version.new('4.2') ? :exists : :exists?

      # Use serialize/deserialize key of GlobalID.
      GLOBALID_KEY = "_sc_globalid"

      # Crucial part of whole enqueuing job.
      def should_enque? time
        return false unless status == "enabled"
        return false unless not_past_scheduled_time?(time)
        return false unless not_enqueued_after?(time)

        enqueue = Sidekiq.redis do |conn|
          conn.zadd(job_enqueued_key, formatted_enqueue_time(time), formatted_last_time(time))
        end
        enqueue == true || enqueue == 1
      end

      # Remove previous information about run times,
      # this will clear Redis and make sure that Redis will not overflow with memory.
      def remove_previous_enques time
        Sidekiq.redis do |conn|
          conn.zremrangebyscore(job_enqueued_key, 0, "(#{(time.to_f - REMEMBER_THRESHOLD).to_s}")
        end
      end

      # Test if job should be enqueued.
      def test_and_enque_for_time! time
        if should_enque?(time)
          enque!

          remove_previous_enques(time)
        end
      end

      # Enqueue cron job to queue.
      def enque! time = Time.now.utc
        @last_enqueue_time = time

        klass_const =
            begin
              Sidekiq::Cron::Support.constantize(@klass.to_s)
            rescue NameError
              nil
            end

        jid =
          if klass_const
            if is_active_job?(klass_const)
              enqueue_active_job(klass_const).try :provider_job_id
            else
              enqueue_sidekiq_worker(klass_const)
            end
          else
            if @active_job
              Sidekiq::Client.push(active_job_message)
            else
              Sidekiq::Client.push(sidekiq_worker_message)
            end
          end

        save_last_enqueue_time
        add_jid_history jid
        Sidekiq.logger.debug { "enqueued #{@name}: #{@message}" }
      end

      def is_active_job?(klass = nil)
        @active_job || defined?(ActiveJob::Base) && (klass || Sidekiq::Cron::Support.constantize(@klass.to_s)) < ActiveJob::Base
      rescue NameError
        false
      end

      def date_as_argument?
        !!@date_as_argument
      end

      def enqueue_args
        args = date_as_argument? ? @args + [Time.now.to_f] : @args
        deserialize_argument(args)
      end

      def enqueue_active_job(klass_const)
        klass_const.set(queue: @queue).perform_later(*enqueue_args)
      end

      def enqueue_sidekiq_worker(klass_const)
        klass_const.set(queue: queue_name_with_prefix).perform_async(*enqueue_args)
      end

      # Sidekiq worker message.
      def sidekiq_worker_message
        message = @message.is_a?(String) ? Sidekiq.load_json(@message) : @message
        message["args"] = enqueue_args
        message
      end

      def queue_name_with_prefix
        return @queue unless is_active_job?

        if !"#{@active_job_queue_name_delimiter}".empty?
          queue_name_delimiter = @active_job_queue_name_delimiter
        elsif defined?(ActiveJob::Base) && defined?(ActiveJob::Base.queue_name_delimiter) && !ActiveJob::Base.queue_name_delimiter.empty?
          queue_name_delimiter = ActiveJob::Base.queue_name_delimiter
        else
          queue_name_delimiter = '_'
        end

        if !"#{@active_job_queue_name_prefix}".empty?
          queue_name = "#{@active_job_queue_name_prefix}#{queue_name_delimiter}#{@queue}"
        elsif defined?(ActiveJob::Base) && defined?(ActiveJob::Base.queue_name_prefix) && !"#{ActiveJob::Base.queue_name_prefix}".empty?
          queue_name = "#{ActiveJob::Base.queue_name_prefix}#{queue_name_delimiter}#{@queue}"
        else
          queue_name = @queue
        end

        queue_name
      end

      # Active Job has different structure how it is loading data from Sidekiq
      # queue, it creates a wrapper around job.
      def active_job_message
        {
          'class'        => 'ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper',
          'wrapped'      => @klass,
          'queue'        => @queue_name_with_prefix,
          'description'  => @description,
          'args'         => [{
            'job_class'  => @klass,
            'job_id'     => SecureRandom.uuid,
            'queue_name' => @queue_name_with_prefix,
            'arguments'  => enqueue_args
          }]
        }
      end

      # Load cron jobs from Hash.
      # Input structure should look like:
      # {
      #   'name_of_job' => {
      #     'class'       => 'MyClass',
      #     'cron'        => '1 * * * *',
      #     'args'        => '(OPTIONAL) [Array or Hash]',
      #     'description' => '(OPTIONAL) Description of job'
      #   },
      #   'My super iber cool job' => {
      #     'class' => 'SecondClass',
      #     'cron'  => '*/5 * * * *'
      #   }
      # }
      #
      def self.load_from_hash(hash, options = {})
        array = hash.map do |key, job|
          job['name'] = key
          job
        end
        load_from_array(array, options)
      end

      # Like #load_from_hash.
      # If exists old jobs in Redis but removed from args, destroy old jobs.
      def self.load_from_hash!(hash, options = {})
        destroy_removed_jobs(hash.keys)
        load_from_hash(hash, options)
      end

      # Load cron jobs from Array.
      # Input structure should look like:
      # [
      #   {
      #     'name'        => 'name_of_job',
      #     'class'       => 'MyClass',
      #     'cron'        => '1 * * * *',
      #     'args'        => '(OPTIONAL) [Array or Hash]',
      #     'description' => '(OPTIONAL) Description of job'
      #   },
      #   {
      #     'name'  => 'Cool Job for Second Class',
      #     'class' => 'SecondClass',
      #     'cron'  => '*/5 * * * *'
      #   }
      # ]
      #
      def self.load_from_array(array, options = {})
        errors = {}
        array.each do |job_data|
          job = new(job_data.merge(options))
          errors[job.name] = job.errors unless job.save
        end
        errors
      end

      # Like #load_from_array.
      # If exists old jobs in Redis but removed from args, destroy old jobs.
      def self.load_from_array!(array, options = {})
        job_names = array.map { |job| job["name"] }
        destroy_removed_jobs(job_names)
        load_from_array(array, options)
      end

      # Get all cron jobs.
      def self.all
        job_hashes = nil
        Sidekiq.redis do |conn|
          set_members = conn.smembers(jobs_key)
          job_hashes = conn.pipelined do |pipeline|
            set_members.each do |key|
              pipeline.hgetall(key)
            end
          end
        end
        job_hashes.compact.reject(&:empty?).collect do |h|
          # No need to fetch missing args from Redis since we just got this hash from there
          Sidekiq::Cron::Job.new(h.merge(fetch_missing_args: false))
        end
      end

      def self.count
        out = 0
        Sidekiq.redis do |conn|
          out = conn.scard(jobs_key)
        end
        out
      end

      def self.find name
        # If name is hash try to get name from it.
        name = name[:name] || name['name'] if name.is_a?(Hash)
        return unless exists? name

        output = nil
        Sidekiq.redis do |conn|
          output = Job.new conn.hgetall( redis_key(name) )
        end
        output if output && output.valid?
      end

      # Create new instance of cron job.
      def self.create hash
        new(hash).save
      end

      # Destroy job by name.
      def self.destroy name
        # If name is hash try to get name from it.
        name = name[:name] || name['name'] if name.is_a?(Hash)

        if job = find(name)
          job.destroy
        else
          false
        end
      end

      attr_accessor :name, :cron, :description, :klass, :args, :message
      attr_reader   :last_enqueue_time, :fetch_missing_args, :source

      def initialize input_args = {}
        args = Hash[input_args.map{ |k, v| [k.to_s, v] }]
        @fetch_missing_args = args.delete('fetch_missing_args')
        @fetch_missing_args = true if @fetch_missing_args.nil?

        @name = args["name"]
        @cron = args["cron"]
        @description = args["description"] if args["description"]
        @source = args["source"] == "schedule" ? "schedule" : "dynamic"

        # Get class from klass or class.
        @klass = args["klass"] || args["class"]

        # Set status of job.
        @status = args['status'] || status_from_redis

        # Set last enqueue time - from args or from existing job.
        if args['last_enqueue_time'] && !args['last_enqueue_time'].empty?
          @last_enqueue_time = parse_enqueue_time(args['last_enqueue_time'])
        else
          @last_enqueue_time = last_enqueue_time_from_redis
        end

        # Get right arguments for job.
        @symbolize_args = args["symbolize_args"] == true || ("#{args["symbolize_args"]}" =~ (/^(true|t|yes|y|1)$/i)) == 0 || false
        @args = parse_args(args["args"])

        @date_as_argument = args["date_as_argument"] == true || ("#{args["date_as_argument"]}" =~ (/^(true|t|yes|y|1)$/i)) == 0 || false

        @active_job = args["active_job"] == true || ("#{args["active_job"]}" =~ (/^(true|t|yes|y|1)$/i)) == 0 || false
        @active_job_queue_name_prefix = args["queue_name_prefix"]
        @active_job_queue_name_delimiter = args["queue_name_delimiter"]

        if args["message"]
          @message = args["message"]
          message_data = Sidekiq.load_json(@message) || {}
          @queue = message_data['queue'] || "default"
        elsif @klass
          message_data = {
            "class" => @klass.to_s,
            "args"  => @args,
          }

          # Get right data for message,
          # only if message wasn't specified before.
          klass_data = case @klass
            when Class
              @klass.get_sidekiq_options
            when String
              begin
                Sidekiq::Cron::Support.constantize(@klass).get_sidekiq_options
              rescue Exception => e
                # Unknown class
                {"queue"=>"default"}
              end
          end

          message_data = klass_data.merge(message_data)

          # Override queue if setted in config,
          # only if message is hash - can be string (dumped JSON).
          if args['queue']
            @queue = message_data['queue'] = args['queue']
          else
            @queue = message_data['queue'] || "default"
          end

          @message = message_data
        end

        @queue_name_with_prefix = queue_name_with_prefix
      end

      def status
        @status
      end

      def disable!
        @status = "disabled"
        save
      end

      def enable!
        @status = "enabled"
        save
      end

      def enabled?
        @status == "enabled"
      end

      def disabled?
        !enabled?
      end

      def pretty_message
        JSON.pretty_generate Sidekiq.load_json(message)
      rescue JSON::ParserError
        message
      end

      def status_from_redis
        out = "enabled"
        if fetch_missing_args
          Sidekiq.redis do |conn|
            status = conn.hget redis_key, "status"
            out = status if status
          end
        end
        out
      end

      def last_enqueue_time_from_redis
        out = nil
        if fetch_missing_args
          Sidekiq.redis do |conn|
            out = parse_enqueue_time(conn.hget(redis_key, "last_enqueue_time")) rescue nil
          end
        end
        out
      end

      def jid_history_from_redis
        out =
          Sidekiq.redis do |conn|
            conn.lrange(jid_history_key, 0, -1) rescue nil
          end

        out && out.map do |jid_history_raw|
          Sidekiq.load_json jid_history_raw
        end
      end

      # Export job data to hash.
      def to_hash
        hash = {
          name: @name,
          klass: @klass.to_s,
          cron: @cron,
          description: @description,
          source: @source,
          args: @args.is_a?(String) ? @args : Sidekiq.dump_json(@args || []),
          message: @message.is_a?(String) ? @message : Sidekiq.dump_json(@message || {}),
          status: @status,
          active_job: @active_job ? "1" : "0",
          queue_name_prefix: @active_job_queue_name_prefix,
          queue_name_delimiter: @active_job_queue_name_delimiter,
          last_enqueue_time: serialized_last_enqueue_time,
          symbolize_args: symbolize_args? ? "1" : "0",
        }

        if date_as_argument?
          hash.merge!(date_as_argument: "1")
        end

        hash
      end

      def errors
        @errors ||= []
      end

      def valid?
        # Clear previous errors.
        @errors = []

        errors << "'name' must be set" if @name.nil? || @name.size == 0
        if @cron.nil? || @cron.size == 0
          errors << "'cron' must be set"
        else
          begin
            @parsed_cron = Fugit.do_parse_cronish(@cron)
          rescue => e
            errors << "'cron' -> #{@cron.inspect} -> #{e.class}: #{e.message}"
          end
        end

        errors << "'klass' (or class) must be set" unless klass_valid

        errors.empty?
      end

      def klass_valid
        case @klass
          when Class
            true
          when String
            @klass.size > 0
          else
        end
      end

      def save
        # If job is invalid, return false.
        return false unless valid?

        Sidekiq.redis do |conn|

          # Add to set of all jobs
          conn.sadd self.class.jobs_key, [redis_key]

          # Add informations for this job!
          conn.hset redis_key, to_hash.transform_values! { |v| v || "" }

          # Add information about last time! - don't enque right after scheduler poller starts!
          time = Time.now.utc
          exists = conn.public_send(REDIS_EXISTS_METHOD, job_enqueued_key)
          conn.zadd(job_enqueued_key, time.to_f.to_s, formatted_last_time(time).to_s) unless exists == true || exists == 1
        end
        Sidekiq.logger.info { "Cron Jobs - added job with name: #{@name}" }
      end

      def save_last_enqueue_time
        Sidekiq.redis do |conn|
          # Update last enqueue time.
          conn.hset redis_key, 'last_enqueue_time', serialized_last_enqueue_time
        end
      end

      def add_jid_history(jid)
        jid_history = {
          jid: jid,
          enqueued: @last_enqueue_time
        }

        @history_size ||= (Sidekiq::Options[:cron_history_size] || 10).to_i - 1
        Sidekiq.redis do |conn|
          conn.lpush jid_history_key,
                     Sidekiq.dump_json(jid_history)
          # Keep only last 10 entries in a fifo manner.
          conn.ltrim jid_history_key, 0, @history_size
        end
      end

      def destroy
        Sidekiq.redis do |conn|
          # Delete from set.
          conn.srem self.class.jobs_key, [redis_key]

          # Delete runned timestamps.
          conn.del job_enqueued_key

          # Delete jid_history.
          conn.del jid_history_key

          # Delete main job.
          conn.del redis_key
        end

        Sidekiq.logger.info { "Cron Jobs - deleted job with name: #{@name}" }
      end

      # Remove all job from cron.
      def self.destroy_all!
        all.each do |job|
          job.destroy
        end
        Sidekiq.logger.info { "Cron Jobs - deleted all jobs" }
      end

      # Remove "removed jobs" between current jobs and new jobs
      def self.destroy_removed_jobs new_job_names
        current_job_names = Sidekiq::Cron::Job.all.filter_map { |j| j.name if j.source == "schedule" }
        removed_job_names = current_job_names - new_job_names
        removed_job_names.each { |j| Sidekiq::Cron::Job.destroy(j) }
        removed_job_names
      end

      # Parse cron specification '* * * * *' and returns
      # time when last run should be performed
      def last_time now = Time.now.utc
        parsed_cron.previous_time(now.utc).utc
      end

      def formatted_enqueue_time now = Time.now.utc
        last_time(now).getutc.to_f.to_s
      end

      def formatted_last_time now = Time.now.utc
        last_time(now).getutc.iso8601
      end

      def self.exists? name
        out = Sidekiq.redis do |conn|
          conn.public_send(REDIS_EXISTS_METHOD, redis_key(name))
        end
        out == true || out == 1
      end

      def exists?
        self.class.exists? @name
      end

      def sort_name
        "#{status == "enabled" ? 0 : 1}_#{name}".downcase
      end

      def args=(args)
        @args = parse_args(args)
      end

      private

      def parsed_cron
        @parsed_cron ||= Fugit.parse_cronish(@cron)
      end

      def not_enqueued_after?(time)
        @last_enqueue_time.nil? || @last_enqueue_time.to_i < last_time(time).to_i
      end

      # Try parsing inbound args into an array.
      # Args from Redis will be encoded JSON,
      # try to load JSON, then failover to string array.
      def parse_args(args)
        case args
        when GlobalID::Identification
          [convert_to_global_id_hash(args)]
        when String
          begin
            parsed_args = Sidekiq.load_json(args)
            symbolize_args? ? symbolize_args(parsed_args) : parsed_args
          rescue JSON::ParserError
            [*args]
          end
        when Hash
          args = serialize_argument(args)
          symbolize_args? ? [symbolize_args(args)] : [args]
        when Array
          args = serialize_argument(args)
          symbolize_args? ? symbolize_args(args) : args
        else
          [*args]
        end
      end

      def symbolize_args?
        @symbolize_args
      end

      def symbolize_args(input)
        if input.is_a?(Array)
          input.map do |arg|
            if arg.respond_to?(:symbolize_keys)
              arg.symbolize_keys
            else
              arg
            end
          end
        elsif input.is_a?(Hash) && input.respond_to?(:symbolize_keys)
          input.symbolize_keys
        else
          input
        end
      end

      def parse_enqueue_time(timestamp)
        DateTime.strptime(timestamp, LAST_ENQUEUE_TIME_FORMAT).to_time.utc
      rescue ArgumentError
        DateTime.parse(timestamp).to_time.utc
      end

      def not_past_scheduled_time?(current_time)
        last_cron_time = parsed_cron.previous_time(current_time).utc
        return false if (current_time.to_i - last_cron_time.to_i) > 60
        true
      end

      # Redis key for set of all cron jobs.
      def self.jobs_key
        "cron_jobs"
      end

      # Redis key for storing one cron job.
      def self.redis_key name
        "cron_job:#{name}"
      end

      # Redis key for storing one cron job.
      def redis_key
        self.class.redis_key @name
      end

      # Redis key for storing one cron job run times (when poller added job to queue)
      def self.job_enqueued_key name
        "cron_job:#{name}:enqueued"
      end

      def self.jid_history_key name
        "cron_job:#{name}:jid_history"
      end

      def job_enqueued_key
        self.class.job_enqueued_key @name
      end

      def jid_history_key
        self.class.jid_history_key @name
      end

      def serialized_last_enqueue_time
        @last_enqueue_time&.strftime(LAST_ENQUEUE_TIME_FORMAT)
      end
      
      def convert_to_global_id_hash(argument)
        { GLOBALID_KEY => argument.to_global_id.to_s }
      rescue URI::GID::MissingModelIdError
        raise "Unable to serialize #{argument.class} " \
          "without an id. (Maybe you forgot to call save?)"
      end

      def deserialize_argument(argument)
        case argument
        when String
          argument
        when Array
          argument.map { |arg| deserialize_argument(arg) }
        when Hash
          if serialized_global_id?(argument)
            deserialize_global_id argument
          else
            argument.transform_values { |v| deserialize_argument(v) }
          end
        else
          argument
        end
      end

      def serialized_global_id?(hash)
        hash.size == 1 && hash.include?(GLOBALID_KEY)
      end

      def deserialize_global_id(hash)
        GlobalID::Locator.locate hash[GLOBALID_KEY]
      end

      def serialize_argument(argument)
        case argument
        when GlobalID::Identification
          convert_to_global_id_hash(argument)
        when Array
          argument.map { |arg| serialize_argument(arg) }
        when Hash
          argument.each_with_object({}) do |(key, value), hash|
            hash[key] = serialize_argument(value)
          end
        else
          argument
        end
      end
    end
  end
end
