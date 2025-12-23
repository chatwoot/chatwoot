# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # Class that encapsulates the logic to decide whether to annotate a model file and its related files or not.
    class AnnotationDecider
      SKIP_ANNOTATION_PREFIX = '# -\*- SkipSchemaAnnotations'

      def initialize(file, options)
        @file = file
        @options = options
      end

      def annotate?
        return false if file_contains_skip_annotation

        begin
          klass = ModelClassGetter.call(@file, @options)

          return false unless klass.respond_to?(:descends_from_active_record?)

          # Skip annotating STI classes
          if @options[:exclude_sti_subclasses] && !klass.descends_from_active_record?
            return false
          end

          return false if klass.abstract_class?
          return false unless klass.table_exists?

          return true
        rescue BadModelFileError => e
          unless @options[:ignore_unknown_models]
            warn "Unable to process #{@file}: #{e.message}"
            warn "\t#{e.backtrace.join("\n\t")}" if @options[:trace]
          end
        rescue => e
          warn "Unable to process #{@file}: #{e.message}"
          warn "\t#{e.backtrace.join("\n\t")}" if @options[:trace]
        end

        false
      end

      private

      def file_contains_skip_annotation
        return false unless File.exist?(@file)

        /#{SKIP_ANNOTATION_PREFIX}.*/o.match?(File.read(@file))
      end
    end
  end
end
