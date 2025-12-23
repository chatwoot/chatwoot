# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ColumnAnnotation
      autoload :AttributesBuilder, "annotate_rb/model_annotator/column_annotation/attributes_builder"
      autoload :TypeBuilder, "annotate_rb/model_annotator/column_annotation/type_builder"
      autoload :ColumnWrapper, "annotate_rb/model_annotator/column_annotation/column_wrapper"
      autoload :AnnotationBuilder, "annotate_rb/model_annotator/column_annotation/annotation_builder"
      autoload :DefaultValueBuilder, "annotate_rb/model_annotator/column_annotation/default_value_builder"
      autoload :ColumnComponent, "annotate_rb/model_annotator/column_annotation/column_component"
    end
  end
end
