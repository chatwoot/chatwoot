# frozen_string_literal: true

module RubyLLM
  module Providers
    class Bedrock
      module Streaming
        # Base module for AWS Bedrock streaming functionality.
        module Base
          def self.included(base)
            base.include ContentExtraction
            base.include MessageProcessing
            base.include PayloadProcessing
            base.include PreludeHandling
          end

          def stream_url
            "model/#{@model_id}/invoke-with-response-stream"
          end

          def stream_response(connection, payload, additional_headers = {}, &block)
            signature = sign_request("#{connection.connection.url_prefix}#{stream_url}", payload:)
            accumulator = StreamAccumulator.new

            response = connection.post stream_url, payload do |req|
              req.headers.merge! build_headers(signature.headers, streaming: block_given?)
              # Merge additional headers, with existing headers taking precedence
              req.headers = additional_headers.merge(req.headers) unless additional_headers.empty?
              req.options.on_data = handle_stream do |chunk|
                accumulator.add chunk
                block.call chunk
              end
            end

            accumulator.to_message(response)
          end

          def handle_stream(&block)
            buffer = +''
            proc do |chunk, _bytes, env|
              if env && env.status != 200
                handle_failed_response(chunk, buffer, env)
              else
                process_chunk(chunk, &block)
              end
            end
          end
        end
      end
    end
  end
end
