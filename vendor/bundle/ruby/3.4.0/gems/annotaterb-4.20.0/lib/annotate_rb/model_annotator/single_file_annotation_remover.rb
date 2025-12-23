# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class SingleFileAnnotationRemover
      class << self
        def call_with_instructions(instruction)
          call(instruction.file, instruction.options)
        end

        def call(file_name, options = Options.from({}))
          return false unless File.exist?(file_name)
          old_content = File.read(file_name)

          parser_klass = FileToParserMapper.map(file_name)

          begin
            parsed_file = FileParser::ParsedFile.new(old_content, "", parser_klass, options).parse
          rescue FileParser::AnnotationFinder::MalformedAnnotation => e
            warn "Unable to process #{file_name}: #{e.message}"
            warn "\t" + e.backtrace.join("\n\t") if @options[:trace]
            return false
          end

          return false if !parsed_file.has_annotations?
          return false if parsed_file.has_skip_string?

          updated_file_content = old_content.sub(parsed_file.annotations_with_whitespace, "")

          File.open(file_name, "wb") { |f| f.puts updated_file_content }

          true
        end
      end
    end
  end
end
