# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'trace_context_payload'

module NewRelic
  module Agent
    module DistributedTracing
      class TraceContext
        VERSION = 0x0

        COMMA = ','
        EQUALS = '='
        INVALID_TRACE_ID = ('0' * 32)
        INVALID_PARENT_ID = ('0' * 16)
        INVALID_VERSION = 'ff'

        TRACE_ID_KEY = 'trace_id'
        TRACE_FLAGS_KEY = 'trace_flags'
        PARENT_ID_KEY = 'parent_id'
        VERSION_KEY = 'version'
        UNDEFINED_FIELDS_KEY = 'undefined_fields'

        TP_VERSION = "(?<#{VERSION_KEY}>[a-f\\d]{2})"
        TP_TRACE_ID = "(?<#{TRACE_ID_KEY}>[a-f\\d]{32})"
        TP_PARENT_ID = "(?<#{PARENT_ID_KEY}>[a-f\\d]{16})"
        TP_TRACE_FLAGS = "(?<#{TRACE_FLAGS_KEY}>\\d{2})"
        TP_UNDEFINED_FIELDS = "(?<#{UNDEFINED_FIELDS_KEY}>-[a-zA-Z\\d-]*)"
        TRACE_PARENT_REGEX = /\A#{TP_VERSION}-#{TP_TRACE_ID}-#{TP_PARENT_ID}-#{TP_TRACE_FLAGS}#{TP_UNDEFINED_FIELDS}?\z/

        TRACE_PARENT_FORMAT_STRING = '%02x-%s-%s-%02x'

        MAX_TRACE_STATE_SIZE = 512 # bytes
        MAX_TRACE_STATE_ENTRY_SIZE = 128 # bytes

        SUPPORTABILITY_TRACE_PARENT_PARSE_EXCEPTION = 'Supportability/TraceContext/TraceParent/Parse/Exception'
        SUPPORTABILITY_TRACE_STATE_PARSE_EXCEPTION = 'Supportability/TraceContext/TraceState/Parse/Exception'
        SUPPORTABILITY_TRACE_STATE_INVALID_NR_ENTRY = 'Supportability/TraceContext/TraceState/InvalidNrEntry'

        class << self
          def insert(format: NewRelic::FORMAT_NON_RACK,
            carrier: nil,
            parent_id: nil,
            trace_id: nil,
            trace_flags: nil,
            trace_state: nil)

            trace_parent_header = trace_parent_header_for_format(format)
            carrier[trace_parent_header] = format_trace_parent( \
              trace_id: trace_id,
              parent_id: parent_id,
              trace_flags: trace_flags
            )

            trace_state_header = trace_state_header_for_format(format)
            carrier[trace_state_header] = trace_state if trace_state && !trace_state.empty?
          end

          def parse(format: NewRelic::FORMAT_NON_RACK,
            carrier: nil,
            trace_state_entry_key: nil)
            trace_parent = extract_traceparent(format, carrier)
            unless trace_parent_valid?(trace_parent)
              NewRelic::Agent.increment_metric(SUPPORTABILITY_TRACE_PARENT_PARSE_EXCEPTION)
              return nil
            end

            begin
              if header_data = extract_tracestate(format, carrier, trace_state_entry_key)
                header_data.trace_parent = trace_parent
                header_data
              end
            rescue Exception
              NewRelic::Agent.increment_metric(SUPPORTABILITY_TRACE_STATE_PARSE_EXCEPTION)
              return nil
            end
          end

          def create_trace_state_entry(entry_key, payload)
            +"#{entry_key}=#{payload}"
          end

          private

          def format_trace_parent(trace_id: nil,
            parent_id: nil,
            trace_flags: nil)
            sprintf(TRACE_PARENT_FORMAT_STRING,
              VERSION,
              trace_id,
              parent_id,
              trace_flags)
          end

          def extract_traceparent(format, carrier)
            header_name = trace_parent_header_for_format(format)
            return unless header = carrier[header_name]

            if matchdata = header.match(TRACE_PARENT_REGEX)
              TRACE_PARENT_REGEX.named_captures.inject({}) do |hash, (name, (index))|
                hash[name] = matchdata[index]
                hash
              end
            end
          end

          def trace_parent_valid?(trace_parent)
            return false if trace_parent.nil?
            return false if trace_parent[TRACE_ID_KEY] == INVALID_TRACE_ID
            return false if trace_parent[PARENT_ID_KEY] == INVALID_PARENT_ID
            return false if trace_parent[VERSION_KEY] == INVALID_VERSION
            return false if trace_parent[VERSION_KEY].to_i(16) == VERSION && !trace_parent[UNDEFINED_FIELDS_KEY].nil?

            true
          end

          def trace_parent_header_for_format(format)
            if format == NewRelic::FORMAT_RACK
              NewRelic::HTTP_TRACEPARENT_KEY
            else
              NewRelic::TRACEPARENT_KEY
            end
          end

          def trace_state_header_for_format(format)
            if format == NewRelic::FORMAT_RACK
              NewRelic::HTTP_TRACESTATE_KEY
            else
              NewRelic::TRACESTATE_KEY
            end
          end

          def extract_tracestate(format, carrier, trace_state_entry_key)
            header_name = trace_state_header_for_format(format)
            header = carrier[header_name]
            return HeaderData.create if header.nil? || header.empty?

            payload = nil
            trace_state_size = 0
            trace_state_vendors = +''
            trace_state = header.split(COMMA).map(&:strip)
            trace_state.reject! do |entry|
              if entry == NewRelic::EMPTY_STR
                false
              else
                vendor_id = entry.slice(0, entry.index(EQUALS))
                if vendor_id == trace_state_entry_key
                  payload = entry.slice!(trace_state_entry_key.size + 1, entry.size)
                  true
                else
                  trace_state_size += entry.size
                  trace_state_vendors << vendor_id << COMMA
                  false
                end
              end
            end

            trace_state_vendors.chomp!(COMMA)

            HeaderData.create(trace_state_payload: payload ? decode_payload(payload) : nil,
              trace_state_entries: trace_state,
              trace_state_size: trace_state_size,
              trace_state_vendors: trace_state_vendors)
          end

          def decode_payload(payload)
            TraceContextPayload.from_s(payload)
          rescue
            if payload
              NewRelic::Agent.increment_metric(SUPPORTABILITY_TRACE_STATE_INVALID_NR_ENTRY)
            end
            return nil
          end
        end

        class HeaderData
          class << self
            def create(trace_parent: nil,
              trace_state_payload: nil,
              trace_state_entries: nil,
              trace_state_size: 0,
              trace_state_vendors: nil)
              new(trace_parent, \
                trace_state_payload, \
                trace_state_entries, \
                trace_state_size, \
                trace_state_vendors)
            end
          end

          def initialize(trace_parent, trace_state_payload, trace_state_entries, trace_state_size, trace_state_vendors)
            @trace_parent = trace_parent
            @trace_state = nil
            @trace_state_entries = trace_state_entries
            @trace_state_payload = trace_state_payload
            @trace_state_size = trace_state_size
            @trace_state_vendors = trace_state_vendors
          end

          attr_accessor :trace_parent, :trace_state_payload, :trace_state_vendors

          def trace_state(trace_state_entry)
            @trace_state ||= join_trace_state(trace_state_entry.size)
            @trace_state_entries = nil

            trace_state_entry = "#{trace_state_entry}#{@trace_state}"
          end

          def trace_id
            @trace_parent[TRACE_ID_KEY]
          end

          def parent_id
            @trace_parent[PARENT_ID_KEY]
          end

          private

          def join_trace_state(trace_state_entry_size)
            return @trace_state || NewRelic::EMPTY_STR if @trace_state_entries.nil? || @trace_state_entries.empty?

            max_size = MAX_TRACE_STATE_SIZE - trace_state_entry_size
            return @trace_state_entries.join(COMMA).prepend(COMMA) if @trace_state_size < max_size

            joined_trace_state = +''

            used_size = 0

            @trace_state_entries.each do |entry|
              entry_size = entry.size + 1
              break if used_size + entry_size > max_size
              next if entry_size > MAX_TRACE_STATE_ENTRY_SIZE

              joined_trace_state << COMMA << entry
              used_size += entry_size
            end

            joined_trace_state
          end
        end
      end
    end
  end
end
