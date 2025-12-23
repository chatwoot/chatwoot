# frozen_string_literal: true

module RubyLLM
  module Providers
    class Bedrock
      module Streaming
        # Module for processing streaming messages from AWS Bedrock.
        module MessageProcessing
          def process_chunk(chunk, &)
            offset = 0
            offset = process_message(chunk, offset, &) while offset < chunk.bytesize
          rescue StandardError => e
            RubyLLM.logger.debug "Error processing chunk: #{e.message}"
            RubyLLM.logger.debug "Chunk size: #{chunk.bytesize}"
          end

          def process_message(chunk, offset, &)
            return chunk.bytesize unless can_read_prelude?(chunk, offset)

            message_info = extract_message_info(chunk, offset)
            return find_next_message(chunk, offset) unless message_info

            process_valid_message(chunk, offset, message_info, &)
          end

          def process_valid_message(chunk, offset, message_info, &)
            payload = extract_payload(chunk, message_info[:headers_end], message_info[:payload_end])
            return find_next_message(chunk, offset) unless valid_payload?(payload)

            process_payload(payload, &)
            offset + message_info[:total_length]
          end

          private

          def extract_message_info(chunk, offset)
            total_length, headers_length = read_prelude(chunk, offset)
            return unless valid_lengths?(total_length, headers_length)

            message_end = offset + total_length
            return unless chunk.bytesize >= message_end

            headers_end, payload_end = calculate_positions(offset, total_length, headers_length)
            return unless valid_positions?(headers_end, payload_end, chunk.bytesize)

            { total_length:, headers_length:, headers_end:, payload_end: }
          end

          def extract_payload(chunk, headers_end, payload_end)
            chunk[headers_end...payload_end]
          end

          def valid_payload?(payload)
            return false if payload.nil? || payload.empty?

            json_start = payload.index('{')
            json_end = payload.rindex('}')

            return false if json_start.nil? || json_end.nil? || json_start >= json_end

            true
          end
        end
      end
    end
  end
end
