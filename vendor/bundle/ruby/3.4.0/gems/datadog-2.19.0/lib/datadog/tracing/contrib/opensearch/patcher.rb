# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative '../ext'
require_relative '../integration'
require_relative '../patcher'
require_relative '../../../core/telemetry/logger'

module Datadog
  module Tracing
    module Contrib
      module OpenSearch
        # Patcher enables patching of 'opensearch' module.
        module Patcher
          include Contrib::Patcher

          module_function

          def patch
            require 'uri'
            require 'json'
            require_relative 'quantize'

            ::OpenSearch::Transport::Client.prepend(Client)
          end

          # Patches OpenSearch::Transport::Client module
          module Client
            # rubocop:disable Metrics/MethodLength
            # rubocop:disable Metrics/AbcSize
            def perform_request(method, path, params = {}, body = nil, headers = nil)
              response = nil
              # rubocop:disable Metrics/BlockLength
              Tracing.trace('opensearch.query', service: datadog_configuration[:service_name]) do |span|
                begin
                  # Set generic tags
                  span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                  span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CLIENT)
                  span.set_tag(Contrib::Ext::DB::TAG_SYSTEM, Ext::TAG_SYSTEM)

                  # Set argument tags
                  span.set_tag(OpenSearch::Ext::TAG_METHOD, method)
                  span.set_tag(OpenSearch::Ext::TAG_PATH, path)

                  tag_params(params, span)
                  tag_body(body, span)

                  # Parse url
                  original_url = transport.get_connection.full_url(path, {})
                  url = URI.parse(original_url)
                  host = url.host
                  port = url.port
                  scheme = url.scheme
                  # Set url.user to nil to remove sensitive information (i.e. user's username and password)
                  url.user = nil

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

                  # Set url tags
                  span.set_tag(OpenSearch::Ext::TAG_URL, url)
                  span.set_tag(OpenSearch::Ext::TAG_HOST, host)
                  span.set_tag(OpenSearch::Ext::TAG_PORT, port)
                  span.set_tag(OpenSearch::Ext::TAG_SCHEME, scheme)

                  span.set_tag(Tracing::Metadata::Ext::TAG_PEER_HOSTNAME, host) if host

                  # Define span resource
                  quantized_url = if datadog_configuration[:resource_pattern] == Ext::RELATIVE_RESOURCE_PATTERN
                                    OpenSearch::Quantize.format_url(url.path)
                                  else # Default to Ext::ABSOLUTE_RESOURCE_PATTERN
                                    OpenSearch::Quantize.format_url(url)
                                  end
                  span.resource = "#{method} #{quantized_url}"
                  Contrib::SpanAttributeSchema.set_peer_service!(span, Ext::PEER_SERVICE_SOURCES)
                rescue StandardError => e
                  Datadog.logger.error(e.message)
                  Datadog::Core::Telemetry::Logger.report(e)
                  # TODO: Refactor the code to streamline the execution without ensure
                ensure
                  begin
                    response = super
                  rescue => e
                    status_code = ::OpenSearch::Transport::Transport::ERRORS.key(e.class)
                    span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, status_code) if status_code
                    raise
                  end
                  # Set post-response tags
                  if response
                    if response.respond_to?(:status)
                      span.set_tag(Tracing::Metadata::Ext::HTTP::TAG_STATUS_CODE, response.status)
                    end
                    if response.respond_to?(:headers) && (response.headers || {})['content-length']
                      span.set_tag(
                        OpenSearch::Ext::TAG_RESPONSE_CONTENT_LENGTH,
                        response.headers['content-length'].to_i
                      )
                    end
                  end
                end
              end
              # rubocop:enable Metrics/BlockLength
              # rubocop:enable Metrics/AbcSize
              response
            end

            def tag_params(params, span)
              return unless params

              params = JSON.generate(params) unless params.is_a?(String)
              span.set_tag(OpenSearch::Ext::TAG_PARAMS, params)
            end

            def tag_body(body, span)
              return unless body

              body = JSON.generate(body) unless body.is_a?(String)
              quantize_options = datadog_configuration[:quantize]
              quantized_body = OpenSearch::Quantize.format_body(
                body,
                quantize_options
              )
              span.set_tag(OpenSearch::Ext::TAG_BODY, quantized_body)
            end

            def datadog_configuration
              Datadog.configuration.tracing[:opensearch]
            end
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end
  end
end
