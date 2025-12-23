# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module FileParser
      autoload :AnnotationFinder, "annotate_rb/model_annotator/file_parser/annotation_finder"
      autoload :CustomParser, "annotate_rb/model_annotator/file_parser/custom_parser"
      autoload :ParsedFile, "annotate_rb/model_annotator/file_parser/parsed_file"
      autoload :ParsedFileResult, "annotate_rb/model_annotator/file_parser/parsed_file_result"
      autoload :YmlParser, "annotate_rb/model_annotator/file_parser/yml_parser"
    end
  end
end
