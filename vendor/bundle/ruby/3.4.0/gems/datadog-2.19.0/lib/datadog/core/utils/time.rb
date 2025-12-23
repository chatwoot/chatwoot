# frozen_string_literal: true

module Datadog
  module Core
    module Utils
      # Common database-related utility functions.
      module Time
        module_function

        # Current monotonic time
        #
        # @param unit [Symbol] unit for the resulting value, same as ::Process#clock_gettime, defaults to :float_second
        # @return [Numeric] timestamp in the requested unit, since some unspecified starting point
        def get_time(unit = :float_second)
          Process.clock_gettime(Process::CLOCK_MONOTONIC, unit)
        end

        # Current wall time.
        #
        # @return [Time] current time object
        def now
          ::Time.now
        end

        # Overrides the implementation of `#now
        # with the provided callable.
        #
        # Overriding the method `#now` instead of
        # indirectly calling `block` removes
        # one level of method call overhead.
        #
        # @param block [Proc] block that returns a `Time` object representing the current wall time
        def now_provider=(block)
          class << self
            # Avoid method redefinition warning.
            # `rescue nil` is added in case customers remove the method
            # themselves to squelch the warning.
            begin
              remove_method(:now)
            rescue
              nil
            end
          end
          define_singleton_method(:now, &block)
        end

        # Overrides the implementation of `#get_time
        # with the provided callable.
        #
        # Overriding the method `#get_time` instead of
        # indirectly calling `block` removes
        # one level of method call overhead.
        #
        # @param block [Proc] block that accepts unit and returns timestamp in the requested unit
        def get_time_provider=(block)
          class << self
            # Avoid method redefinition warning
            # `rescue nil` is added in case customers remove the method
            # themselves to squelch the warning.
            begin
              remove_method(:get_time)
            rescue
              nil
            end
          end
          define_singleton_method(:get_time, &block)
        end

        def measure(unit = :float_second)
          before = get_time(unit)
          yield
          after = get_time(unit)
          after - before
        end

        def as_utc_epoch_ns(time)
          # we use #to_r instead of #to_f because Float doesn't have enough precision to represent exact nanoseconds, see
          # https://rubyapi.org/3.0/o/time#method-i-to_f
          (time.to_r * 1_000_000_000).to_i
        end
      end
    end
  end
end
