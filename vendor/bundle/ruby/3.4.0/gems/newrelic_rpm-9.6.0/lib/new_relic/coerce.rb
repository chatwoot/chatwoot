# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Coerce
    module_function

    # We really don't want to send bad values to the collector, and it doesn't
    # accept types like Rational that have occasionally slipped into our data.
    #
    # These non-bang methods are intended to safely coerce things into the form we want,
    # to provide documentation of expected types on to_collector_array methods,
    # and to log failures if totally invalid data gets into outgoing data

    def int(value, context = nil)
      Integer(value)
    rescue => error
      log_failure(value, Integer, context, error)
      0
    end

    def int_or_nil(value, context = nil)
      return nil if value.nil?

      Integer(value)
    rescue => error
      log_failure(value, Integer, context, error)
      nil
    end

    def float(value, context = nil)
      result = Float(value)
      raise "Value #{result.inspect} is not finite." unless result.finite?

      result
    rescue => error
      log_failure(value, Float, context, error)
      0.0
    end

    def string(value, context = nil)
      return value if value.nil?

      String(value)
    rescue => error
      log_failure(value.class, String, context, error)
      EMPTY_STR
    end

    def scalar(val)
      case val
      when String, Integer, TrueClass, FalseClass, NilClass
        val
      when Float
        if val.finite?
          val
        end
      when Symbol
        val.to_s
      else
        "#<#{val.class.to_s}>"
      end
    end

    def int!(value)
      return nil unless value_or_nil(value)

      Integer(value)
    end

    # Use when you plan to perform a boolean check using the integer 1
    # for true and the integer 0 for false
    # String values will be converted to 0
    def boolean_int!(value)
      value.to_i
    end

    def float!(value, precision = NewRelic::PRIORITY_PRECISION)
      return nil unless value_or_nil(value)

      value.to_f.round(precision)
    end

    def value_or_nil(value)
      return nil if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      value
    end

    def log_failure(value, type, context, error)
      msg = "Unable to convert '#{value}' to #{type}"
      msg += " in context '#{context}'" if context
      NewRelic::Agent.logger.warn(msg, error)
    end
  end
end
