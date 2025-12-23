# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class FileToParserMapper
      class UnsupportedFileTypeError < StandardError; end

      MAP = {
        ".rb" => FileParser::CustomParser,
        ".yml" => FileParser::YmlParser
      }.freeze

      class << self
        def map(file_name)
          extension = File.extname(file_name).downcase
          parser = MAP[extension]

          raise UnsupportedFileTypeError, "File '#{file_name}' does not have a supported file type." if parser.nil?

          parser
        end
      end
    end
  end
end
