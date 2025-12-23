# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module ForeignKeyAnnotation
      autoload :AnnotationBuilder, "annotate_rb/model_annotator/foreign_key_annotation/annotation_builder"
      autoload :Annotation, "annotate_rb/model_annotator/foreign_key_annotation/annotation"
      autoload :ForeignKeyComponent, "annotate_rb/model_annotator/foreign_key_annotation/foreign_key_component"
      autoload :ForeignKeyComponentBuilder, "annotate_rb/model_annotator/foreign_key_annotation/foreign_key_component_builder"
    end
  end
end
