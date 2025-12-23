# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # A plain old Ruby object (PORO) that contains all necessary information for SingleFileAnnotator
    class SingleFileAnnotatorInstruction
      def initialize(file, annotation, position, options)
        @file = file # Path to file
        @annotation = annotation # Annotation string
        @position = position # Position in the file where to write the annotation to
        @options = options
      end

      attr_reader :file, :annotation, :position, :options
    end
  end
end
