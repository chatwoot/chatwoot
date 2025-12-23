# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'cgi'

module OpenTelemetry
  module Baggage
    module Propagation
      # Propagates baggage using the W3C Baggage format
      class TextMapPropagator
        # Maximums according to W3C Baggage spec
        MAX_ENTRIES = 180
        MAX_ENTRY_LENGTH = 4096
        MAX_TOTAL_LENGTH = 8192

        BAGGAGE_KEY = 'baggage'
        FIELDS = [BAGGAGE_KEY].freeze

        private_constant :BAGGAGE_KEY, :FIELDS, :MAX_ENTRIES, :MAX_ENTRY_LENGTH, :MAX_TOTAL_LENGTH

        # Inject in-process baggage into the supplied carrier.
        #
        # @param [Carrier] carrier The mutable carrier to inject baggage into
        # @param [Context] context The context to read baggage from
        # @param [optional Setter] setter If the optional setter is provided, it
        #   will be used to write context into the carrier, otherwise the default
        #   text map setter will be used.
        def inject(carrier, context: Context.current, setter: Context::Propagation.text_map_setter)
          baggage = OpenTelemetry::Baggage.raw_entries(context: context)

          return if baggage.nil? || baggage.empty?

          encoded_baggage = encode(baggage)
          setter.set(carrier, BAGGAGE_KEY, encoded_baggage) unless encoded_baggage&.empty?
          nil
        end

        # Extract remote baggage from the supplied carrier.
        # If extraction fails or there is no baggage to extract,
        # then the original context will be returned
        #
        # @param [Carrier] carrier The carrier to get the header from
        # @param [optional Context] context Context to be updated with the baggage
        #   extracted from the carrier. Defaults to +Context.current+.
        # @param [optional Getter] getter If the optional getter is provided, it
        #   will be used to read the header from the carrier, otherwise the default
        #   text map getter will be used.
        #
        # @return [Context] context updated with extracted baggage, or the original context
        #   if extraction fails
        def extract(carrier, context: Context.current, getter: Context::Propagation.text_map_getter)
          header = getter.get(carrier, BAGGAGE_KEY)
          return context if header.nil? || header.empty?

          entries = header.gsub(/\s/, '').split(',')

          OpenTelemetry::Baggage.build(context: context) do |builder|
            entries.each do |entry|
              # Note metadata is currently unused in OpenTelemetry, but is part
              # the W3C spec where it's referred to as properties. We preserve
              # the properties (as-is) so that they can be propagated elsewhere.
              kv, meta = entry.split(';', 2)
              k, v = kv.split('=').map!(&CGI.method(:unescape))
              builder.set_value(k, v, metadata: meta)
            end
          end
        rescue StandardError => e
          OpenTelemetry.logger.debug "Error extracting W3C baggage: #{e.message}"
          context
        end

        # Returns the predefined propagation fields. If your carrier is reused, you
        # should delete the fields returned by this method before calling +inject+.
        #
        # @return [Array<String>] a list of fields that will be used by this propagator.
        def fields
          FIELDS
        end

        private

        def encode(baggage)
          result = +''
          encoded_count = 0
          baggage.each_pair do |key, entry|
            break unless encoded_count < MAX_ENTRIES

            encoded_entry = encode_value(key, entry)
            next unless encoded_entry.size <= MAX_ENTRY_LENGTH &&
                        encoded_entry.size + result.size <= MAX_TOTAL_LENGTH

            result << encoded_entry << ','
            encoded_count += 1
          end
          result.chop!
        end

        def encode_value(key, entry)
          result = +"#{CGI.escape(key.to_s)}=#{CGI.escape(entry.value.to_s)}"
          # We preserve metadata received on extract and assume it's already formatted
          # for transport. It's sent as-is without further processing.
          result << ";#{entry.metadata}" if entry.metadata
          result
        end
      end
    end
  end
end
