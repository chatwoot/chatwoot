# frozen_string_literal: true

require "sidekiq/middleware/modules"

module Sidekiq
  # Middleware is code configured to run before/after
  # a job is processed.  It is patterned after Rack
  # middleware. Middleware exists for the client side
  # (pushing jobs onto the queue) as well as the server
  # side (when jobs are actually processed).
  #
  # Callers will register middleware Classes and Sidekiq will
  # create new instances of the middleware for every job. This
  # is important so that instance state is not shared accidentally
  # between job executions.
  #
  # To add middleware for the client:
  #
  #   Sidekiq.configure_client do |config|
  #     config.client_middleware do |chain|
  #       chain.add MyClientHook
  #     end
  #   end
  #
  # To modify middleware for the server, just call
  # with another block:
  #
  #   Sidekiq.configure_server do |config|
  #     config.server_middleware do |chain|
  #       chain.add MyServerHook
  #       chain.remove ActiveRecord
  #     end
  #   end
  #
  # To insert immediately preceding another entry:
  #
  #   Sidekiq.configure_client do |config|
  #     config.client_middleware do |chain|
  #       chain.insert_before ActiveRecord, MyClientHook
  #     end
  #   end
  #
  # To insert immediately after another entry:
  #
  #   Sidekiq.configure_client do |config|
  #     config.client_middleware do |chain|
  #       chain.insert_after ActiveRecord, MyClientHook
  #     end
  #   end
  #
  # This is an example of a minimal server middleware:
  #
  #   class MyServerHook
  #     include Sidekiq::ServerMiddleware
  #
  #     def call(job_instance, msg, queue)
  #       logger.info "Before job"
  #       redis {|conn| conn.get("foo") } # do something in Redis
  #       yield
  #       logger.info "After job"
  #     end
  #   end
  #
  # This is an example of a minimal client middleware, note
  # the method must return the result or the job will not push
  # to Redis:
  #
  #   class MyClientHook
  #     include Sidekiq::ClientMiddleware
  #
  #     def call(job_class, msg, queue, redis_pool)
  #       logger.info "Before push"
  #       result = yield
  #       logger.info "After push"
  #       result
  #     end
  #   end
  #
  module Middleware
    class Chain
      include Enumerable

      # Iterate through each middleware in the chain
      def each(&block)
        entries.each(&block)
      end

      # @api private
      def initialize(config = nil) # :nodoc:
        @config = config
        @entries = nil
        yield self if block_given?
      end

      def entries
        @entries ||= []
      end

      def copy_for(capsule)
        chain = Sidekiq::Middleware::Chain.new(capsule)
        chain.instance_variable_set(:@entries, entries.dup)
        chain
      end

      # Remove all middleware matching the given Class
      # @param klass [Class]
      def remove(klass)
        entries.delete_if { |entry| entry.klass == klass }
      end

      # Add the given middleware to the end of the chain.
      # Sidekiq will call `klass.new(*args)` to create a clean
      # copy of your middleware for every job executed.
      #
      #   chain.add(Statsd::Metrics, { collector: "localhost:8125" })
      #
      # @param klass [Class] Your middleware class
      # @param *args [Array<Object>] Set of arguments to pass to every instance of your middleware
      def add(klass, *args)
        remove(klass)
        entries << Entry.new(@config, klass, *args)
      end

      # Identical to {#add} except the middleware is added to the front of the chain.
      def prepend(klass, *args)
        remove(klass)
        entries.insert(0, Entry.new(@config, klass, *args))
      end

      # Inserts +newklass+ before +oldklass+ in the chain.
      # Useful if one middleware must run before another middleware.
      def insert_before(oldklass, newklass, *args)
        i = entries.index { |entry| entry.klass == newklass }
        new_entry = i.nil? ? Entry.new(@config, newklass, *args) : entries.delete_at(i)
        i = entries.index { |entry| entry.klass == oldklass } || 0
        entries.insert(i, new_entry)
      end

      # Inserts +newklass+ after +oldklass+ in the chain.
      # Useful if one middleware must run after another middleware.
      def insert_after(oldklass, newklass, *args)
        i = entries.index { |entry| entry.klass == newklass }
        new_entry = i.nil? ? Entry.new(@config, newklass, *args) : entries.delete_at(i)
        i = entries.index { |entry| entry.klass == oldklass } || entries.count - 1
        entries.insert(i + 1, new_entry)
      end

      # @return [Boolean] if the given class is already in the chain
      def exists?(klass)
        any? { |entry| entry.klass == klass }
      end
      alias_method :include?, :exists?

      # @return [Boolean] if the chain contains no middleware
      def empty?
        @entries.nil? || @entries.empty?
      end

      def retrieve
        map(&:make_new)
      end

      def clear
        entries.clear
      end

      # Used by Sidekiq to execute the middleware at runtime
      # @api private
      def invoke(*args, &block)
        return yield if empty?

        chain = retrieve
        traverse(chain, 0, args, &block)
      end

      private

      def traverse(chain, index, args, &block)
        if index >= chain.size
          yield
        else
          chain[index].call(*args) do
            traverse(chain, index + 1, args, &block)
          end
        end
      end
    end

    # Represents each link in the middleware chain
    # @api private
    class Entry
      attr_reader :klass

      def initialize(config, klass, *args)
        @config = config
        @klass = klass
        @args = args
      end

      def make_new
        x = @klass.new(*@args)
        x.config = @config if @config && x.respond_to?(:config=)
        x
      end
    end
  end
end
