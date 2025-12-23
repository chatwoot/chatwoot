# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module Annotation
      autoload :AnnotationBuilder, "annotate_rb/model_annotator/annotation/annotation_builder"
      autoload :MainHeader, "annotate_rb/model_annotator/annotation/main_header"
      autoload :SchemaHeader, "annotate_rb/model_annotator/annotation/schema_header"
      autoload :MarkdownHeader, "annotate_rb/model_annotator/annotation/markdown_header"
      autoload :SchemaFooter, "annotate_rb/model_annotator/annotation/schema_footer"
    end
  end
end
