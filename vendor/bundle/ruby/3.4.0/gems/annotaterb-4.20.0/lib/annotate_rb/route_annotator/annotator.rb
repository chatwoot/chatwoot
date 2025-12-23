# frozen_string_literal: true

module AnnotateRb
  module RouteAnnotator
    class Annotator
      class << self
        # TODO: Deprecate
        def do_annotations(options = {})
          add_annotations(options)
        end

        def add_annotations(options = {})
          new(options).add_annotations
        end

        def remove_annotations(options = {})
          new(options).remove_annotations
        end
      end

      def initialize(options = {})
        @options = options
      end

      def add_annotations
        routes_file = File.join("config", "routes.rb")
        AnnotationProcessor.execute(@options, routes_file).tap do |result|
          puts result
        end
      end

      def remove_annotations
        routes_file = File.join("config", "routes.rb")
        RemovalProcessor.execute(@options, routes_file).tap do |result|
          puts result
        end
      end
    end
  end
end
