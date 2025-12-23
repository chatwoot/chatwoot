# frozen_string_literal: true

module Datadog
  module Core
    # Chunks list of elements into batches
    module Chunker
      module_function

      # Chunks a list into batches of at most +max_chunk_size+ elements each.
      #
      # An exception can occur if a single element is too large. That single
      # element will be returned in its own chunk. You have to verify by yourself
      # when such elements are returned.
      #
      # @param list [Enumerable] list of elements
      # @param max_chunk_size [Numeric] maximum acceptable chunk size
      # @return [Enumerable] lazy list of chunks
      def chunk_by_size(list, max_chunk_size)
        chunk_agg = 0
        list.slice_before do |elem|
          size = elem.size
          chunk_agg += size
          if chunk_agg > max_chunk_size
            # Can't fit element in current chunk, start a new one.
            chunk_agg = size
            true
          else
            # Add to current chunk
            false
          end
        end
      end
    end
  end
end
