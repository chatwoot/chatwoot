# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class ProjectAnnotationRemover
      def initialize(options)
        @options = options
      end

      def remove_annotations
        project_model_files = model_files

        removal_instructions = project_model_files.map do |path, filename|
          file = File.join(path, filename)

          if AnnotationDecider.new(file, @options).annotate?
            _instructions = build_instructions_for_file(file)
          end
        end.flatten.compact

        deannotated = removal_instructions.map do |instruction|
          if SingleFileAnnotationRemover.call_with_instructions(instruction)
            instruction.file
          end
        rescue => e
          warn "Unable to process #{File.join(instruction.file)}: #{e.message}"
          warn "\t" + e.backtrace.join("\n\t") if @options[:trace]
        end.flatten.compact

        if deannotated.empty?
          puts "Model files unchanged."
        else
          puts "Removed annotations (#{deannotated.length}) from: #{deannotated.join(", ")}"
        end
      end

      private

      def build_instructions_for_file(file)
        klass = ModelClassGetter.call(file, @options)

        instructions = []

        klass.reset_column_information
        model_name = klass.name.underscore
        table_name = klass.table_name

        model_instruction = SingleFileRemoveAnnotationInstruction.new(file, @options)
        instructions << model_instruction

        related_files = RelatedFilesListBuilder.new(file, model_name, table_name, @options).build
        related_file_instructions = related_files.map do |f, _position_key|
          _instruction = SingleFileRemoveAnnotationInstruction.new(f, @options)
        end
        instructions.concat(related_file_instructions)

        instructions
      end

      def model_files
        @model_files ||= ModelFilesGetter.call(@options)
      end
    end
  end
end
