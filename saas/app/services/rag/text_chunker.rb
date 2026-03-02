# frozen_string_literal: true

# Splits a long text string into overlapping chunks suitable for embedding.
# Uses a recursive character-based strategy similar to LangChain's RecursiveCharacterTextSplitter.
module Rag
  class TextChunker
    DEFAULT_CHUNK_SIZE = 1000 # tokens ≈ characters / 4, but we measure in chars for simplicity
    DEFAULT_OVERLAP    = 200
    SEPARATORS = ["\n\n", "\n", '. ', ', ', ' ', ''].freeze

    def initialize(chunk_size: DEFAULT_CHUNK_SIZE, overlap: DEFAULT_OVERLAP)
      @chunk_size = chunk_size
      @overlap = overlap
    end

    # Returns an array of { text:, index: } hashes
    def split(text)
      return [] if text.blank?

      chunks = recursive_split(text, SEPARATORS)
      chunks.each_with_index.map { |chunk, idx| { text: chunk.strip, index: idx } }
             .reject { |c| c[:text].blank? }
    end

    private

    def recursive_split(text, separators)
      return [text] if text.length <= @chunk_size

      separator = separators.first
      remaining_separators = separators[1..]

      parts = separator.present? ? text.split(separator) : text.chars.each_slice(@chunk_size).map(&:join)

      merge_splits(parts, separator, remaining_separators)
    end

    def merge_splits(parts, separator, remaining_separators)
      chunks = []
      current = +''

      parts.each do |part|
        candidate = current.empty? ? part : "#{current}#{separator}#{part}"

        if candidate.length <= @chunk_size
          current = candidate
        else
          # Current chunk is full — flush it
          if current.present?
            chunks << current
            # Keep overlap from the end of the flushed chunk
            current = overlap_text(current, separator) + separator + part
            # If still too big after overlap, try splitting further
            if current.length > @chunk_size
              if remaining_separators.any?
                chunks.concat(recursive_split(current, remaining_separators))
                current = +''
              else
                chunks << current
                current = +''
              end
            end
          else
            # Single part exceeds chunk_size — try splitting with finer separators
            if remaining_separators.any?
              chunks.concat(recursive_split(part, remaining_separators))
            else
              chunks << part
            end
            current = +''
          end
        end
      end

      chunks << current if current.present?
      chunks
    end

    # Grab roughly @overlap characters from the end of text
    def overlap_text(text, _separator)
      return '' if @overlap <= 0

      text.last(@overlap)
    end
  end
end
