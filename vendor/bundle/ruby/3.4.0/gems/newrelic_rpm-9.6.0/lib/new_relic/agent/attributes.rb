# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/attribute_processing'

module NewRelic
  module Agent
    class Attributes
      KEY_LIMIT = 255
      VALUE_LIMIT = 255
      COUNT_LIMIT = 64

      attr_reader :custom_attributes

      def initialize(filter)
        @filter = filter

        @custom_attributes = {}
        @agent_attributes = {}
        @intrinsic_attributes = {}

        @custom_destinations = {}
        @agent_destinations = {}
        @already_warned_count_limit = nil
      end

      def add_agent_attribute(key, value, default_destinations)
        destinations = @filter.apply(key, default_destinations)
        return if destinations == AttributeFilter::DST_NONE

        @agent_destinations[key] = destinations
        add(@agent_attributes, key, value)
      end

      def add_agent_attribute_with_key_check(key, value, default_destinations)
        if exceeds_bytesize_limit?(key, KEY_LIMIT)
          NewRelic::Agent.logger.debug("Agent attribute #{key} was dropped for exceeding key length limit #{KEY_LIMIT}")
          return
        end

        add_agent_attribute(key, value, default_destinations)
      end

      def add_intrinsic_attribute(key, value)
        add(@intrinsic_attributes, key, value)
      end

      def merge_untrusted_agent_attributes(attributes, prefix, default_destinations)
        return if @filter.high_security?
        return if !@filter.might_allow_prefix?(prefix)

        AttributeProcessing.flatten_and_coerce(attributes, prefix) do |k, v|
          add_agent_attribute_with_key_check(k, v, AttributeFilter::DST_NONE)
        end
      end

      def merge_custom_attributes(other)
        return unless Agent.config[:'custom_attributes.enabled']
        return if other.empty?

        AttributeProcessing.flatten_and_coerce(other) do |k, v|
          add_custom_attribute(k, v)
        end
      end

      def custom_attributes_for(destination)
        for_destination(@custom_attributes, @custom_destinations, destination)
      end

      def agent_attributes_for(destination)
        for_destination(@agent_attributes, @agent_destinations, destination)
      end

      def intrinsic_attributes_for(destination)
        if destination == NewRelic::Agent::AttributeFilter::DST_TRANSACTION_TRACER ||
            destination == NewRelic::Agent::AttributeFilter::DST_ERROR_COLLECTOR
          @intrinsic_attributes
        else
          NewRelic::EMPTY_HASH
        end
      end

      private

      def add_custom_attribute(key, value)
        if @custom_attributes.size >= COUNT_LIMIT
          unless @already_warned_count_limit
            NewRelic::Agent.logger.warn("Custom attributes count exceeded limit of #{COUNT_LIMIT}. Any additional custom attributes during this transaction will be dropped.")
            @already_warned_count_limit = true
          end
          return
        end

        if @filter.high_security?
          NewRelic::Agent.logger.debug("Unable to add custom attribute #{key} while in high security mode.")
          return
        end

        if exceeds_bytesize_limit?(key, KEY_LIMIT)
          NewRelic::Agent.logger.warn("Custom attribute key '#{key}' was longer than limit of #{KEY_LIMIT} bytes. This attribute will be dropped.")
          return
        end

        destinations = @filter.apply(key, AttributeFilter::DST_ALL)
        return if destinations == AttributeFilter::DST_NONE

        @custom_destinations[key] = destinations
        add(@custom_attributes, key, value)
      end

      def add(attributes, key, value)
        return if value.nil?

        if exceeds_bytesize_limit?(value, VALUE_LIMIT)
          value = slice(value)
        end

        attributes[key] = value
      end

      def for_destination(attributes, calculated_destinations, destination)
        # Avoid allocating anything if there are no attrs at all
        return NewRelic::EMPTY_HASH if attributes.empty?

        attributes.inject({}) do |memo, (key, value)|
          if @filter.allows?(calculated_destinations[key], destination)
            memo[key] = value
          end
          memo
        end
      end

      def exceeds_bytesize_limit?(value, limit)
        if value.respond_to?(:bytesize)
          value.bytesize > limit
        elsif value.is_a?(Symbol)
          value.to_s.bytesize > limit
        else
          false
        end
      end

      # Take one byte past our limit. Why? This lets us unconditionally chop!
      # the end. It'll either remove the one-character-too-many we have, or
      # peel off the partial, mangled character left by the byteslice.
      def slice(incoming)
        result = incoming.to_s.byteslice(0, VALUE_LIMIT + 1)
        result.chop!
      end
    end
  end
end
