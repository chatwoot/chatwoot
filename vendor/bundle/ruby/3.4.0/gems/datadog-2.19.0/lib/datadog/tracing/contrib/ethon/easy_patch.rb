# frozen_string_literal: true

require 'uri'

require_relative '../../../core/utils/hash'
require_relative '../../metadata/ext'
require_relative '../http'
require_relative 'ext'
require_relative '../http_annotation_helper'

module Datadog
  module Tracing
    module Contrib
      module Ethon
        # Ethon EasyPatch
        module EasyPatch
          def self.included(base)
            base.prepend(InstanceMethods)
          end

          # InstanceMethods - implementing instrumentation
          module InstanceMethods
            include Contrib::HttpAnnotationHelper

            def http_request(url, action_name, options = {})
              load_datadog_configuration_for(url)
              return super unless Tracing.enabled?

              # It's tricky to get HTTP method from libcurl
              @datadog_method = action_name.to_s.upcase
              super
            end

            def headers=(headers)
              # Store headers to call this method again when span is ready
              @datadog_original_headers = headers
              super
            end

            def perform
              load_datadog_configuration_for(url)
              return super unless Tracing.enabled?

              datadog_before_request
              super
            end

            def complete
              return super unless Tracing.enabled?

              begin
                response_options = mirror.options
                response_code = (response_options[:response_code] || response_options[:code]).to_i
                if response_code.zero?
                  return_code = response_options[:return_code]
                  message = return_code ? ::Ethon::Curl.easy_strerror(return_code) : 'unknown reason'
                  set_span_error_message("Request has failed: #{message}")
                else
                  @datadog_span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response_code)
                  if Tracing::Metadata::Ext::HTTP::ERROR_RANGE.cover?(response_code)
                    set_span_error_message("Request has failed with HTTP error: #{response_code}")
                  end
                end

                @datadog_span.set_tags(
                  Datadog.configuration.tracing.header_tags.response_tags(
                    Core::Utils::Hash::CaseInsensitiveWrapper.new(parse_response_headers)
                  )
                )
              ensure
                @datadog_span.finish
                @datadog_span = nil
              end
              super
            end

            def reset
              super
            ensure
              @datadog_span = nil
              @datadog_method = nil
              @datadog_original_headers = nil
              @datadog_configuration = nil
            end

            # Starts or retrieves the already started Easy request span.
            #
            # When tracing in Multi request context, child spans for each Easy
            # request are created early, and then finished as their HTTP response
            # becomes available. Because many Easy requests are open at the same time,
            # many Datadog::Tracing::Spans are also open at the same time. To avoid each separate
            # Easy request becoming the parented to the previous open request we set
            # the +parent_span+ parameter with the parent Multi span. This correctly
            # assigns all open Easy spans to the currently executing Multi context.
            #
            # @param [Datadog::Tracing::Span] continue_from the Multi span, if executing in a Multi context.
            def datadog_before_request(continue_from: nil)
              load_datadog_configuration_for(url)

              trace_options = continue_from ? { continue_from: continue_from } : {}
              uri = try_parse_uri

              @datadog_span = Tracing.trace(
                Ext::SPAN_REQUEST,
                service: uri ? service_name(uri.host, datadog_configuration) : datadog_configuration[:service_name],
                type: Tracing::Metadata::Ext::HTTP::TYPE_OUTBOUND,
                **trace_options
              )
              datadog_trace = Tracing.active_trace

              datadog_tag_request

              if Tracing::Distributed::PropagationPolicy.enabled?(
                global_config: datadog_configuration,
                trace: datadog_trace
              )
                @datadog_original_headers ||= {}
                Contrib::HTTP.inject(datadog_trace, @datadog_original_headers)
                self.headers = @datadog_original_headers
              end
            end

            def datadog_span_started?
              instance_variable_defined?(:@datadog_span) && !@datadog_span.nil?
            end

            private

            attr_reader :datadog_configuration

            def datadog_tag_request
              span = @datadog_span
              method = Ext::NOT_APPLICABLE_METHOD
              method = @datadog_method.to_s if instance_variable_defined?(:@datadog_method) && !@datadog_method.nil?
              span.resource = method

              if datadog_configuration[:peer_service]
                span.set_tag(
                  Tracing::Metadata::Ext::TAG_PEER_SERVICE,
                  datadog_configuration[:peer_service]
                )
              end

              # Tag original global service name if not used
              if span.service != Datadog.configuration.service
                span.set_tag(Tracing::Contrib::Ext::Metadata::TAG_BASE_SERVICE, Datadog.configuration.service)
              end

              # Set analytics sample rate
              Contrib::Analytics.set_sample_rate(span, analytics_sample_rate) if analytics_enabled?

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)

              uri = try_parse_uri
              return unless uri

              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_URL, uri.path)
              span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_METHOD, method)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_HOST, uri.host)
              span.set_tag(Tracing::Metadata::Ext::NET::TAG_TARGET_PORT, uri.port)
              span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, uri.host)

              if @datadog_original_headers
                span.set_tags(
                  Datadog.configuration.tracing.header_tags.request_tags(
                    Core::Utils::Hash::CaseInsensitiveWrapper.new(@datadog_original_headers)
                  )
                )
              end

              Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
            end

            def set_span_error_message(message)
              # Sets span error from message, in case there is no exception available
              @datadog_span.status = Tracing::Metadata::Ext::Errors::STATUS
              @datadog_span.set_tag(Tracing::Metadata::Ext::Errors::TAG_MSG, message)
            end

            # rubocop:disable Lint/SuppressedException
            def try_parse_uri
              URI.parse(url)
            rescue URI::InvalidURIError
            end
            # rubocop:enable Lint/SuppressedException

            def load_datadog_configuration_for(host = :default)
              @datadog_configuration = Datadog.configuration.tracing[:ethon, host]
            end

            def analytics_enabled?
              Contrib::Analytics.enabled?(datadog_configuration[:analytics_enabled])
            end

            def analytics_sample_rate
              datadog_configuration[:analytics_sample_rate]
            end

            # `#response_headers` returns a "\n" concatenated String containing:
            # * The HTTP Status-Line.
            # * The response headers.
            # * A trailing "\n".
            #
            # This method extracts only the headers from it.
            def parse_response_headers
              return {} if response_headers.empty?

              lines = response_headers.split("\n")

              lines = lines[1..(lines.size - 1)] # Remove Status-Line and trailing whitespace.

              # Find only well-behaved HTTP headers.
              lines.map do |line|
                header = line.split(':', 2)
                header.size != 2 ? nil : header
              end.compact.to_h
            end
          end
        end
      end
    end
  end
end
