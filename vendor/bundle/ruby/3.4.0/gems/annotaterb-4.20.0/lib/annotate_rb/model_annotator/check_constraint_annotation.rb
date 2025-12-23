# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module CheckConstraintAnnotation
      autoload :AnnotationBuilder, "annotate_rb/model_annotator/check_constraint_annotation/annotation_builder"
      autoload :Annotation, "annotate_rb/model_annotator/check_constraint_annotation/annotation"
      autoload :CheckConstraintComponent, "annotate_rb/model_annotator/check_constraint_annotation/check_constraint_component"
    end
  end
end
