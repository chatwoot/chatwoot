# frozen_string_literal: true

module RubyLLM
  module Providers
    class Bedrock
      module Streaming
        # Module for handling message preludes in AWS Bedrock streaming responses.
        module PreludeHandling
          def can_read_prelude?(chunk, offset)
            chunk.bytesize - offset >= 12
          end

          def read_prelude(chunk, offset)
            total_length = chunk[offset...(offset + 4)].unpack1('N')
            headers_length = chunk[(offset + 4)...(offset + 8)].unpack1('N')
            [total_length, headers_length]
          end

          def valid_lengths?(total_length, headers_length)
            valid_length_constraints?(total_length, headers_length)
          end

          def calculate_positions(offset, total_length, headers_length)
            headers_end = offset + 12 + headers_length
            payload_end = offset + total_length - 4 # Subtract 4 bytes for message CRC
            [headers_end, payload_end]
          end

          def valid_positions?(headers_end, payload_end, chunk_size)
            return false if headers_end >= payload_end
            return false if headers_end >= chunk_size
            return false if payload_end > chunk_size

            true
          end

          def find_next_message(chunk, offset)
            next_prelude = find_next_prelude(chunk, offset + 4)
            next_prelude || chunk.bytesize
          end

          def find_next_prelude(chunk, start_offset)
            scan_range(chunk, start_offset).each do |pos|
              return pos if valid_prelude_at_position?(chunk, pos)
            end
            nil
          end

          private

          def scan_range(chunk, start_offset)
            (start_offset...(chunk.bytesize - 8))
          end

          def valid_prelude_at_position?(chunk, pos)
            lengths = extract_potential_lengths(chunk, pos)
            valid_length_constraints?(*lengths)
          end

          def extract_potential_lengths(chunk, pos)
            [
              chunk[pos...(pos + 4)].unpack1('N'),
              chunk[(pos + 4)...(pos + 8)].unpack1('N')
            ]
          end

          def valid_length_constraints?(total_length, headers_length)
            return false if total_length.nil? || headers_length.nil?
            return false if total_length <= 0 || total_length > 1_000_000
            return false if headers_length <= 0 || headers_length >= total_length

            true
          end
        end
      end
    end
  end
end
