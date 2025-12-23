# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative 'request_wrapper'
require_relative '../helper'

module NewRelic
  module Agent
    module Instrumentation
      module GRPC
        module Client
          include NewRelic::Agent::Instrumentation::GRPC::Helper

          INSTRUMENTATION_NAME = 'gRPC_Client'

          def issue_request_with_tracing(grpc_type, method, requests, marshal, unmarshal,
            deadline:, return_op:, parent:, credentials:, metadata:)
            return yield unless trace_with_newrelic?

            NewRelic::Agent.record_instrumentation_invocation(INSTRUMENTATION_NAME)

            segment = request_segment(method)
            request_wrapper = NewRelic::Agent::Instrumentation::GRPC::Client::RequestWrapper.new(@host)
            # do not insert CAT headers for gRPC requests https://github.com/newrelic/newrelic-ruby-agent/issues/1730
            segment.add_request_headers(request_wrapper) unless CrossAppTracing.cross_app_enabled?
            metadata.merge!(request_wrapper.instance_variable_get(:@newrelic_metadata))
            grpc_message = nil
            grpc_status = 0

            NewRelic::Agent.disable_all_tracing do
              begin
                yield
              rescue => e
                NewRelic::Agent.notice_error(e)
                grpc_status, grpc_message = grpc_status_and_message_from_exception(e)
                raise
              end
            end
          ensure
            add_attributes(segment, grpc_message: grpc_message, grpc_status: grpc_status, grpc_type: grpc_type)
            ::NewRelic::Agent::Transaction::Segment.finish(segment)
          end

          private

          def add_attributes(segment, attributes_hash)
            return unless segment

            attributes_hash.each do |attr, value|
              segment.add_agent_attribute(attr, value)
            end
            segment.record_agent_attributes = true
          end

          def grpc_status_and_message_from_exception(exception)
            return unless exception.message =~ /^(\d+):(\w+)\./

            [Regexp.last_match(1).to_i, Regexp.last_match(2)]
          end

          def request_segment(method)
            cleaned = cleaned_method(method)
            NewRelic::Agent::Tracer.start_external_request_segment(
              library: 'gRPC',
              uri: method_uri(cleaned),
              procedure: cleaned
            )
          end

          def method_uri(method)
            return unless @host && method

            "grpc://#{@host}/#{method}"
          end

          def interceptor?
            self.class.name.eql?('GRPC::InterceptorRegistry')
          end

          def trace_with_newrelic?
            return @trace_with_newrelic unless @trace_with_newrelic.nil? # check for nil, not false

            @trace_with_newrelic = if interceptor?
              false
            else
              !host_denylisted?(@host)
            end
          end
        end
      end
    end
  end
end
