# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/agent/transaction/segment'
require 'new_relic/agent/http_clients/uri_util'

module NewRelic
  module Agent
    class Transaction
      #
      # This class represents an external segment in a transaction trace.
      #
      # @api public
      class ExternalRequestSegment < Segment
        NR_SYNTHETICS_HEADER = 'X-NewRelic-Synthetics'
        NR_SYNTHETICS_INFO_HEADER = 'X-NewRelic-Synthetics-Info'
        APP_DATA_KEY = 'NewRelicAppData'

        EXTERNAL_ALL = 'External/all'
        EXTERNAL_ALL_WEB = 'External/allWeb'
        EXTERNAL_ALL_OTHER = 'External/allOther'
        MISSING_STATUS_CODE = 'MissingHTTPStatusCode'

        attr_reader :library, :uri, :procedure, :http_status_code
        attr_writer :record_agent_attributes

        def initialize(library, uri, procedure, start_time = nil) # :nodoc:
          @library = library
          @uri = HTTPClients::URIUtil.obfuscated_uri(uri)
          @procedure = procedure
          @host_header = nil
          @app_data = nil
          @http_status_code = nil
          @record_agent_attributes = false
          super(nil, nil, start_time)
        end

        def name # :nodoc:
          @name ||= "External/#{host}/#{library}/#{procedure}"
        end

        def host # :nodoc:
          @host_header || uri.host
        end

        # By default external request segments only have errors and the http
        # url recorded as agent attributes. To have all the agent attributes
        # recorded, use the attr_writer like so `segment.record_agent_attributes = true`
        # See: SpanEventPrimitive#for_external_request_segment
        def record_agent_attributes?
          @record_agent_attributes
        end

        # This method adds New Relic request headers to a given request made to an
        # external API and checks to see if a host header is used for the request.
        # If a host header is used, it updates the segment name to match the host
        # header.
        #
        # @param [NewRelic::Agent::HTTPClients::AbstractRequest] request the request
        # object (must belong to a subclass of NewRelic::Agent::HTTPClients::AbstractRequest)
        #
        # @api public
        def add_request_headers(request)
          process_host_header(request)
          synthetics_header = transaction&.raw_synthetics_header
          synthetics_info_header = transaction&.raw_synthetics_info_header
          insert_synthetics_header(request, synthetics_header, synthetics_info_header) if synthetics_header

          return unless record_metrics?

          transaction.distributed_tracer.insert_headers(request)
        rescue => e
          NewRelic::Agent.logger.error('Error in add_request_headers', e)
        end

        # This method extracts app data from an external response if present. If
        # a valid cross-app ID is found, the name of the segment is updated to
        # reflect the cross-process ID and transaction name.
        #
        # @param [Hash] response a hash of response headers
        #
        # @api public
        def read_response_headers(response)
          return unless record_metrics? && CrossAppTracing.cross_app_enabled?
          return unless CrossAppTracing.response_has_crossapp_header?(response)

          unless data = CrossAppTracing.extract_appdata(response)
            NewRelic::Agent.logger.debug("Couldn't extract_appdata from external segment response")
            return
          end

          if CrossAppTracing.valid_cross_app_id?(data[0])
            @app_data = data
            update_segment_name
          else
            NewRelic::Agent.logger.debug('External segment response has invalid cross_app_id')
          end
        rescue => e
          NewRelic::Agent.logger.error('Error in read_response_headers', e)
        end

        def cross_app_request? # :nodoc:
          !!@app_data
        end

        def cross_process_id # :nodoc:
          @app_data && @app_data[0]
        end

        def transaction_guid # :nodoc:
          @app_data && @app_data[5]
        end

        def cross_process_transaction_name # :nodoc:
          @app_data && @app_data[1]
        end

        # Obtain an obfuscated +String+ suitable for delivery across public networks that identifies this application
        # and transaction to another application which is also running a New Relic agent. This +String+ can be processed
        # by +process_request_metadata+ on the receiving application.
        #
        # @return [String] obfuscated request metadata to send
        #
        # @api public
        #
        def get_request_metadata
          NewRelic::Agent.record_api_supportability_metric(:get_request_metadata)
          return unless CrossAppTracing.cross_app_enabled?

          if transaction

            # build hash of CAT metadata
            #
            rmd = {
              NewRelicID: NewRelic::Agent.config[:cross_process_id],
              NewRelicTransaction: [
                transaction.guid,
                false,
                transaction.distributed_tracer.cat_trip_id,
                transaction.distributed_tracer.cat_path_hash
              ]
            }

            # flag cross app in the state so transaction knows to add bits to payload
            #
            transaction.distributed_tracer.is_cross_app_caller = true

            # add Synthetics header if we have it
            #
            rmd[:NewRelicSynthetics] = transaction.raw_synthetics_header if transaction.raw_synthetics_header

            # obfuscate the generated request metadata JSON
            #
            obfuscator.obfuscate(::JSON.dump(rmd))

          end
        rescue => e
          NewRelic::Agent.logger.error('error during get_request_metadata', e)
        end

        # Process obfuscated +String+ sent from a called application that is also running a New Relic agent and
        # save information in current transaction for inclusion in a trace. This +String+ is generated by
        # +get_response_metadata+ on the receiving application.
        #
        # @param response_metadata [String] received obfuscated response metadata
        #
        # @api public
        #
        def process_response_metadata(response_metadata)
          NewRelic::Agent.record_api_supportability_metric(:process_response_metadata)
          if transaction
            app_data = ::JSON.parse(obfuscator.deobfuscate(response_metadata))[APP_DATA_KEY]

            # validate cross app id
            #
            if Array === app_data and CrossAppTracing.trusted_valid_cross_app_id?(app_data[0])
              @app_data = app_data
              update_segment_name
            else
              NewRelic::Agent.logger.error('error processing response metadata: invalid/non-trusted ID')
            end
          end

          nil
        rescue => e
          NewRelic::Agent.logger.error('error during process_response_metadata', e)
        end

        def record_metrics
          add_unscoped_metrics
          super
        end

        def process_response_headers(response) # :nodoc:
          set_http_status_code(response)
          read_response_headers(response)
        end

        private

        # Only sets the http_status_code if response.status_code is non-empty value
        def set_http_status_code(response)
          if response.respond_to?(:status_code)
            @http_status_code = response.status_code if response.has_status_code?
          else
            NewRelic::Agent.logger.warn("Cannot extract HTTP Status Code from response #{response.class.to_s}")
            NewRelic::Agent.record_metric("#{name}/#{MISSING_STATUS_CODE}", 1)
          end
        end

        def insert_synthetics_header(request, header, info)
          request[NR_SYNTHETICS_HEADER] = header
          request[NR_SYNTHETICS_INFO_HEADER] = info if info
        end

        def segment_complete
          params[:uri] = uri.to_s
          if cross_app_request?
            params[:transaction_guid] = transaction_guid
          end

          super
        end

        def process_host_header(request)
          if @host_header = request.host_from_header
            update_segment_name
          end
        end

        def add_unscoped_metrics
          @unscoped_metrics = [EXTERNAL_ALL,
            "External/#{host}/all",
            suffixed_rollup_metric]

          if cross_app_request?
            @unscoped_metrics << "ExternalApp/#{host}/#{cross_process_id}/all"
          end
        end

        def suffixed_rollup_metric
          if Transaction.recording_web_transaction?
            EXTERNAL_ALL_WEB
          else
            EXTERNAL_ALL_OTHER
          end
        end

        def update_segment_name
          if @app_data
            @name = "ExternalTransaction/#{host}/#{cross_process_id}/#{cross_process_transaction_name}"
          else
            @name = "External/#{host}/#{library}/#{procedure}"
          end
        end

        def obfuscator
          CrossAppTracing.obfuscator
        end

        def record_span_event
          # don't record a span event if the transaction is ignored
          return if transaction.ignore?

          aggregator = ::NewRelic::Agent.agent.span_event_aggregator
          priority = transaction.priority
          aggregator.record(priority: priority) do
            SpanEventPrimitive.for_external_request_segment(self)
          end
        end
      end
    end
  end
end
