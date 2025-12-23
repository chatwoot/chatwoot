# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class Annotator
      class << self
        def do_annotations(options)
          new(options).do_annotations
        end

        def remove_annotations(options)
          new(options).remove_annotations
        end
      end

      def initialize(options)
        @options = options
      end

      def do_annotations
        ProjectAnnotator.new(@options).annotate
      end

      def remove_annotations
        ProjectAnnotationRemover.new(@options).remove_annotations
      end
    end
  end
end
