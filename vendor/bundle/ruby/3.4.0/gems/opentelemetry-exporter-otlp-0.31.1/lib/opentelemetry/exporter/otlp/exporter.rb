# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/common'
require 'opentelemetry/sdk'
require 'net/http'
require 'zlib'

require 'google/rpc/status_pb'

require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

module OpenTelemetry
  module Exporter
    module OTLP
      # An OpenTelemetry trace exporter that sends spans over HTTP as Protobuf encoded OTLP ExportTraceServiceRequests.
      class Exporter # rubocop:disable Metrics/ClassLength
        SUCCESS = OpenTelemetry::SDK::Trace::Export::SUCCESS
        FAILURE = OpenTelemetry::SDK::Trace::Export::FAILURE
        private_constant(:SUCCESS, :FAILURE)

        # Default timeouts in seconds.
        KEEP_ALIVE_TIMEOUT = 30
        RETRY_COUNT = 5
        private_constant(:KEEP_ALIVE_TIMEOUT, :RETRY_COUNT)

        ERROR_MESSAGE_INVALID_HEADERS = 'headers must be a String with comma-separated URL Encoded UTF-8 k=v pairs or a Hash'
        private_constant(:ERROR_MESSAGE_INVALID_HEADERS)

        DEFAULT_USER_AGENT = "OTel-OTLP-Exporter-Ruby/#{OpenTelemetry::Exporter::OTLP::VERSION} Ruby/#{RUBY_VERSION} (#{RUBY_PLATFORM}; #{RUBY_ENGINE}/#{RUBY_ENGINE_VERSION})".freeze

        def self.ssl_verify_mode
          if ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_PEER')
            OpenSSL::SSL::VERIFY_PEER
          elsif ENV.key?('OTEL_RUBY_EXPORTER_OTLP_SSL_VERIFY_NONE')
            OpenSSL::SSL::VERIFY_NONE
          else
            OpenSSL::SSL::VERIFY_PEER
          end
        end

        def initialize(endpoint: nil,
                       certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CERTIFICATE'),
                       client_certificate_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE', 'OTEL_EXPORTER_OTLP_CLIENT_CERTIFICATE'),
                       client_key_file: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_CLIENT_KEY', 'OTEL_EXPORTER_OTLP_CLIENT_KEY'),
                       ssl_verify_mode: Exporter.ssl_verify_mode,
                       headers: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_HEADERS', 'OTEL_EXPORTER_OTLP_HEADERS', default: {}),
                       compression: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_COMPRESSION', 'OTEL_EXPORTER_OTLP_COMPRESSION', default: 'gzip'),
                       timeout: OpenTelemetry::Common::Utilities.config_opt('OTEL_EXPORTER_OTLP_TRACES_TIMEOUT', 'OTEL_EXPORTER_OTLP_TIMEOUT', default: 10),
                       metrics_reporter: nil)
          @uri = prepare_endpoint(endpoint)

          raise ArgumentError, "unsupported compression key #{compression}" unless compression.nil? || %w[gzip none].include?(compression)

          @http = http_connection(@uri, ssl_verify_mode, certificate_file, client_certificate_file, client_key_file)

          @path = @uri.path
          @headers = prepare_headers(headers)
          @timeout = timeout.to_f
          @compression = compression
          @metrics_reporter = metrics_reporter || OpenTelemetry::SDK::Trace::Export::MetricsReporter
          @shutdown = false
        end

        # Called to export sampled {OpenTelemetry::SDK::Trace::SpanData} structs.
        #
        # @param [Enumerable<OpenTelemetry::SDK::Trace::SpanData>] span_data the
        #   list of recorded {OpenTelemetry::SDK::Trace::SpanData} structs to be
        #   exported.
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] the result of the export.
        def export(span_data, timeout: nil)
          return FAILURE if @shutdown

          send_bytes(encode(span_data), timeout: timeout)
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#force_flush} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def force_flush(timeout: nil)
          SUCCESS
        end

        # Called when {OpenTelemetry::SDK::Trace::TracerProvider#shutdown} is called, if
        # this exporter is registered to a {OpenTelemetry::SDK::Trace::TracerProvider}
        # object.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        def shutdown(timeout: nil)
          @shutdown = true
          @http.finish if @http.started?
          SUCCESS
        end

        private

        # Builds span flags based on whether the parent span context is remote.
        # This follows the OTLP specification for span flags.
        def build_span_flags(parent_span_is_remote, base_flags)
          # Extract integer value from TraceFlags object if needed
          # Derive the low 8-bit W3C trace flags using the public API.
          base_flags_int =
            if base_flags.sampled?
              1
            else
              0
            end

          has_remote_mask = Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK
          is_remote_mask = Opentelemetry::Proto::Trace::V1::SpanFlags::SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK

          flags = base_flags_int | has_remote_mask
          flags |= is_remote_mask if parent_span_is_remote
          flags
        end

        def http_connection(uri, ssl_verify_mode, certificate_file, client_certificate_file, client_key_file)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == 'https'
          http.verify_mode = ssl_verify_mode
          http.ca_file = certificate_file unless certificate_file.nil?
          http.cert = OpenSSL::X509::Certificate.new(File.read(client_certificate_file)) unless client_certificate_file.nil?
          http.key = OpenSSL::PKey::RSA.new(File.read(client_key_file)) unless client_key_file.nil?
          http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
          http
        end

        # The around_request is a private method that provides an extension
        # point for the exporters network calls. The default behaviour
        # is to not trace these operations.
        #
        # An example use case would be to prepend a patch, or extend this class
        # and override this method's behaviour to explicitly trace the HTTP request.
        # This would allow you to trace your export pipeline.
        def around_request
          OpenTelemetry::Common::Utilities.untraced { yield } # rubocop:disable Style/ExplicitBlockArgument
        end

        def send_bytes(bytes, timeout:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          return FAILURE if bytes.nil?

          @metrics_reporter.record_value('otel.otlp_exporter.message.uncompressed_size', value: bytes.bytesize)

          request = Net::HTTP::Post.new(@path)
          if @compression == 'gzip'
            request.add_field('Content-Encoding', 'gzip')
            body = Zlib.gzip(bytes)
            @metrics_reporter.record_value('otel.otlp_exporter.message.compressed_size', value: body.bytesize)
          else
            body = bytes
          end
          request.body = body
          request.add_field('Content-Type', 'application/x-protobuf')
          @headers.each { |key, value| request.add_field(key, value) }

          retry_count = 0
          timeout ||= @timeout
          start_time = OpenTelemetry::Common::Utilities.timeout_timestamp

          around_request do
            remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
            return FAILURE if remaining_timeout.zero?

            @http.open_timeout = remaining_timeout
            @http.read_timeout = remaining_timeout
            @http.write_timeout = remaining_timeout
            @http.start unless @http.started?
            response = measure_request_duration { @http.request(request) }

            case response
            when Net::HTTPOK
              response.body # Read and discard body
              SUCCESS
            when Net::HTTPServiceUnavailable, Net::HTTPTooManyRequests
              response.body # Read and discard body
              redo if backoff?(retry_after: response['Retry-After'], retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPRequestTimeOut, Net::HTTPGatewayTimeOut, Net::HTTPBadGateway
              response.body # Read and discard body
              redo if backoff?(retry_count: retry_count += 1, reason: response.code)
              FAILURE
            when Net::HTTPNotFound
              log_request_failure(response.code)
              FAILURE
            when Net::HTTPBadRequest, Net::HTTPClientError, Net::HTTPServerError
              log_status(response.body)
              @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => response.code })
              FAILURE
            when Net::HTTPRedirection
              @http.finish
              handle_redirect(response['location'])
              redo if backoff?(retry_after: 0, retry_count: retry_count += 1, reason: response.code)
            else
              @http.finish
              log_request_failure(response.code)
              FAILURE
            end
          rescue Net::OpenTimeout, Net::ReadTimeout
            retry if backoff?(retry_count: retry_count += 1, reason: 'timeout')
            return FAILURE
          rescue OpenSSL::SSL::SSLError => e
            retry if backoff?(retry_count: retry_count += 1, reason: 'openssl_error')
            OpenTelemetry.handle_error(exception: e, message: 'SSL error in OTLP::Exporter#send_bytes')
            return FAILURE
          rescue SocketError
            retry if backoff?(retry_count: retry_count += 1, reason: 'socket_error')
            return FAILURE
          rescue SystemCallError => e
            retry if backoff?(retry_count: retry_count += 1, reason: e.class.name)
            return FAILURE
          rescue EOFError
            retry if backoff?(retry_count: retry_count += 1, reason: 'eof_error')
            return FAILURE
          rescue Zlib::DataError
            retry if backoff?(retry_count: retry_count += 1, reason: 'zlib_error')
            return FAILURE
          rescue StandardError => e
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#send_bytes')
            @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => e.class.to_s })
            return FAILURE
          end
        ensure
          # Reset timeouts to defaults for the next call.
          @http.open_timeout = @timeout
          @http.read_timeout = @timeout
          @http.write_timeout = @timeout
        end

        def handle_redirect(location)
          # TODO: figure out destination and reinitialize @http and @path
        end

        def log_status(body)
          status = Google::Rpc::Status.decode(body)
          details = status.details.map do |detail|
            klass_or_nil = ::Google::Protobuf::DescriptorPool.generated_pool.lookup(detail.type_name).msgclass
            detail.unpack(klass_or_nil) if klass_or_nil
          end.compact
          OpenTelemetry.handle_error(message: "OTLP exporter received rpc.Status{message=#{status.message}, details=#{details}} for uri=#{@uri}")
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error decoding rpc.Status in OTLP::Exporter#log_status')
        end

        def log_request_failure(response_code)
          OpenTelemetry.handle_error(message: "OTLP exporter received http.code=#{response_code} for uri='#{@uri}' in OTLP::Exporter#send_bytes")
          @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => response_code })
        end

        def measure_request_duration
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          begin
            response = yield
          ensure
            stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            duration_ms = 1000.0 * (stop - start)
            @metrics_reporter.record_value('otel.otlp_exporter.request_duration',
                                           value: duration_ms,
                                           labels: { 'status' => response&.code || 'unknown' })
          end
        end

        def backoff?(retry_count:, reason:, retry_after: nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          @metrics_reporter.add_to_counter('otel.otlp_exporter.failure', labels: { 'reason' => reason })
          return false if retry_count > RETRY_COUNT

          sleep_interval = nil
          unless retry_after.nil?
            sleep_interval =
              begin
                Integer(retry_after)
              rescue ArgumentError
                nil
              end
            sleep_interval ||=
              begin
                Time.httpdate(retry_after) - Time.now
              rescue # rubocop:disable Style/RescueStandardError
                nil
              end
            sleep_interval = nil unless sleep_interval&.positive?
          end
          sleep_interval ||= rand(2**retry_count)

          sleep(sleep_interval)
          true
        end

        def encode(span_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
          start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.encode(
            Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.new(
              resource_spans: span_data
                .group_by(&:resource)
                .map do |resource, span_datas|
                  Opentelemetry::Proto::Trace::V1::ResourceSpans.new(
                    resource: Opentelemetry::Proto::Resource::V1::Resource.new(
                      attributes: resource.attribute_enumerator.map { |key, value| as_otlp_key_value(key, value) }
                    ),
                    scope_spans: span_datas
                      .group_by(&:instrumentation_scope)
                      .map do |il, sds|
                        Opentelemetry::Proto::Trace::V1::ScopeSpans.new(
                          scope: Opentelemetry::Proto::Common::V1::InstrumentationScope.new(
                            name: il.name,
                            version: il.version
                          ),
                          spans: sds.map { |sd| as_otlp_span(sd) }
                        )
                      end
                  )
                end
            )
          )
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: 'unexpected error in OTLP::Exporter#encode')
          nil
        ensure
          stop = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          duration_ms = 1000.0 * (stop - start)
          @metrics_reporter.record_value('otel.otlp_exporter.encode_duration',
                                         value: duration_ms)
        end

        def as_otlp_span(span_data) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
          Opentelemetry::Proto::Trace::V1::Span.new(
            trace_id: span_data.trace_id,
            span_id: span_data.span_id,
            trace_state: span_data.tracestate.to_s,
            parent_span_id: span_data.parent_span_id == OpenTelemetry::Trace::INVALID_SPAN_ID ? nil : span_data.parent_span_id,
            name: span_data.name,
            kind: as_otlp_span_kind(span_data.kind),
            start_time_unix_nano: span_data.start_timestamp,
            end_time_unix_nano: span_data.end_timestamp,
            attributes: span_data.attributes&.map { |k, v| as_otlp_key_value(k, v) },
            dropped_attributes_count: span_data.total_recorded_attributes - span_data.attributes&.size.to_i,
            events: span_data.events&.map do |event|
              Opentelemetry::Proto::Trace::V1::Span::Event.new(
                time_unix_nano: event.timestamp,
                name: event.name,
                attributes: event.attributes&.map { |k, v| as_otlp_key_value(k, v) }
                # TODO: track dropped_attributes_count in Span#append_event
              )
            end,
            dropped_events_count: span_data.total_recorded_events - span_data.events&.size.to_i,
            links: span_data.links&.map do |link|
              Opentelemetry::Proto::Trace::V1::Span::Link.new(
                trace_id: link.span_context.trace_id,
                span_id: link.span_context.span_id,
                trace_state: link.span_context.tracestate.to_s,
                attributes: link.attributes&.map { |k, v| as_otlp_key_value(k, v) },
                # TODO: track dropped_attributes_count in Span#trim_links
                flags: build_span_flags(link.span_context.remote?, link.span_context.trace_flags)
              )
            end,
            dropped_links_count: span_data.total_recorded_links - span_data.links&.size.to_i,
            status: span_data.status&.yield_self do |status|
              Opentelemetry::Proto::Trace::V1::Status.new(
                code: as_otlp_status_code(status.code),
                message: status.description
              )
            end,
            flags: build_span_flags(span_data.parent_span_is_remote, span_data.trace_flags)
          )
        end

        def as_otlp_status_code(code)
          case code
          when OpenTelemetry::Trace::Status::OK then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_OK
          when OpenTelemetry::Trace::Status::ERROR then Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_ERROR
          else Opentelemetry::Proto::Trace::V1::Status::StatusCode::STATUS_CODE_UNSET
          end
        end

        def as_otlp_span_kind(kind)
          case kind
          when :internal then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_INTERNAL
          when :server then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_SERVER
          when :client then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CLIENT
          when :producer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_PRODUCER
          when :consumer then Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_CONSUMER
          else Opentelemetry::Proto::Trace::V1::Span::SpanKind::SPAN_KIND_UNSPECIFIED
          end
        end

        def as_otlp_key_value(key, value)
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value(value))
        rescue Encoding::UndefinedConversionError => e
          encoded_value = value.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�')
          OpenTelemetry.handle_error(exception: e, message: "encoding error for key #{key} and value #{encoded_value}")
          Opentelemetry::Proto::Common::V1::KeyValue.new(key: key, value: as_otlp_any_value('Encoding Error'))
        end

        def as_otlp_any_value(value)
          result = Opentelemetry::Proto::Common::V1::AnyValue.new
          case value
          when String
            result.string_value = value
          when Integer
            result.int_value = value
          when Float
            result.double_value = value
          when true, false
            result.bool_value = value
          when Array
            values = value.map { |element| as_otlp_any_value(element) }
            result.array_value = Opentelemetry::Proto::Common::V1::ArrayValue.new(values: values)
          end
          result
        end

        def prepare_endpoint(endpoint)
          endpoint ||= ENV['OTEL_EXPORTER_OTLP_TRACES_ENDPOINT']
          if endpoint.nil?
            endpoint = ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] || 'http://localhost:4318'
            endpoint += '/' unless endpoint.end_with?('/')
            URI.join(endpoint, 'v1/traces')
          elsif endpoint.strip.empty?
            raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}"
          else
            URI(endpoint)
          end
        rescue URI::InvalidURIError
          raise ArgumentError, "invalid url for OTLP::Exporter #{endpoint}"
        end

        def prepare_headers(config_headers)
          headers = case config_headers
                    when String then parse_headers(config_headers)
                    when Hash then config_headers.dup
                    else
                      raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
                    end

          headers['User-Agent'] = "#{headers.fetch('User-Agent', '')} #{DEFAULT_USER_AGENT}".strip

          headers
        end

        def parse_headers(raw)
          entries = raw.split(',')
          raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if entries.empty?

          entries.each_with_object({}) do |entry, headers|
            k, v = entry.split('=', 2).map(&CGI.method(:unescape))
            begin
              k = k.to_s.strip
              v = v.to_s.strip
            rescue Encoding::CompatibilityError
              raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS
            rescue ArgumentError => e
              raise e, ERROR_MESSAGE_INVALID_HEADERS
            end
            raise ArgumentError, ERROR_MESSAGE_INVALID_HEADERS if k.empty? || v.empty?

            headers[k] = v
          end
        end
      end
    end
  end
end
