# frozen_string_literal: true

module Faraday
  module StreamingResponseChecker
    def check_streaming_response(streamed, options = {})
      opts = {
        prefix: '',
        streaming?: true
      }.merge(options)

      expected_response = opts[:prefix] + big_string

      chunks, sizes = streamed.transpose

      # Check that the total size of the chunks (via the last size returned)
      # is the same size as the expected_response
      expect(sizes.last).to eq(expected_response.bytesize)

      start_index = 0
      expected_chunks = []
      chunks.each do |actual_chunk|
        expected_chunk = expected_response[start_index..((start_index + actual_chunk.bytesize) - 1)]
        expected_chunks << expected_chunk
        start_index += expected_chunk.bytesize
      end

      # it's easier to read a smaller portion, so we check that first
      expect(expected_chunks[0][0..255]).to eq(chunks[0][0..255])

      [expected_chunks, chunks].transpose.each do |expected, actual|
        expect(actual).to eq(expected)
      end
    end
  end
end
