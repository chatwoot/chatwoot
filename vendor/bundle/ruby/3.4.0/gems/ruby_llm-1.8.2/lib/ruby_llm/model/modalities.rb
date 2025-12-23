# frozen_string_literal: true

module RubyLLM
  module Model
    # Holds and manages input and output modalities for a language model
    class Modalities
      attr_reader :input, :output

      def initialize(data)
        @input = Array(data[:input]).map(&:to_s)
        @output = Array(data[:output]).map(&:to_s)
      end

      def to_h
        {
          input: input,
          output: output
        }
      end
    end
  end
end
