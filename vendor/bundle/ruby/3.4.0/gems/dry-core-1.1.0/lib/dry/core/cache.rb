# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Core
    # Allows you to cache call results that are solely determined by arguments.
    #
    # @example
    #   require 'dry/core/cache'
    #
    #   class Foo
    #     extend Dry::Core::Cache
    #
    #     def heavy_computation(arg1, arg2)
    #       fetch_or_store(arg1, arg2) { arg1 ^ arg2 }
    #     end
    #   end
    #
    # @api public
    module Cache
      # @api private
      def self.extended(klass)
        super
        klass.include(Methods)
        klass.instance_variable_set(:@__cache__, ::Concurrent::Map.new)
      end

      # @api private
      def inherited(klass)
        super
        klass.instance_variable_set(:@__cache__, cache)
      end

      # @api private
      def cache
        @__cache__
      end

      # Caches a result of the block evaluation
      #
      # @param [Array<Object>] args List of hashable objects
      # @yield An arbitrary block
      #
      # @note beware Proc instance hashes are not equal, i.e. -> { 1 }.hash != -> { 1 }.hash,
      #       this means you shouldn't pass Procs in args unless you're sure
      #       they are always the same instances, otherwise you introduce a memory leak
      #
      # @return [Object] block's return value (cached for subsequent calls with
      #   the same argument values)
      def fetch_or_store(*args, &)
        cache.fetch_or_store(args.hash, &)
      end

      # Instance methods
      module Methods
        # Delegates call to the class-level method
        #
        # @param [Array<Object>] args List of hashable objects
        # @yield An arbitrary block
        #
        # @return [Object] block's return value
        def fetch_or_store(...)
          self.class.fetch_or_store(...)
        end
      end
    end
  end
end
