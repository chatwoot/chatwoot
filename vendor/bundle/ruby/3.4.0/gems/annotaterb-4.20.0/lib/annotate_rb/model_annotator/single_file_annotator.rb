# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class SingleFileAnnotator
      class << self
        def call_with_instructions(instruction)
          call(instruction.file, instruction.annotation, instruction.position, instruction.options)
        end

        # Add a schema block to a file. If the file already contains
        # a schema info block (a comment starting with "== Schema Information"),
        # check if it matches the block that is already there. If so, leave it be.
        # If not, remove the old info block and write a new one.
        #
        # == Returns:
        # true or false depending on whether the file was modified.
        #
        # === Options (opts)
        #  :force<Symbol>:: whether to update the file even if it doesn't seem to need it.
        #  :position_in_*<Symbol>:: where to place the annotated section in fixture or model file,
        #                           :before, :top, :after or :bottom. Default is :before.
        #
        def call(file_name, annotation, annotation_position, options)
          return false unless File.exist?(file_name)
          old_content = File.read(file_name)

          parser_klass = FileToParserMapper.map(file_name)

          begin
            parsed_file = FileParser::ParsedFile.new(old_content, annotation, parser_klass, options).parse
          rescue FileParser::AnnotationFinder::MalformedAnnotation => e
            warn "Unable to process #{file_name}: #{e.message}"
            warn "\t" + e.backtrace.join("\n\t") if @options[:trace]
            return false
          end

          return false if parsed_file.has_skip_string?
          return false if !parsed_file.annotations_changed? && !options[:force]

          abort "AnnotateRb error. #{file_name} needs to be updated, but annotaterb was run with `--frozen`." if options[:frozen]

          updated_file_content = if !parsed_file.has_annotations?
            AnnotatedFile::Generator.new(old_content, annotation, annotation_position, parser_klass, parsed_file, options).generate
          elsif options[:force]
            AnnotatedFile::Generator.new(old_content, annotation, annotation_position, parser_klass, parsed_file, options).generate
          else
            AnnotatedFile::Updater.new(old_content, annotation, annotation_position, parsed_file, options).update
          end

          File.open(file_name, "wb") { |f| f.puts updated_file_content }

          true
        end
      end
    end
  end
end
