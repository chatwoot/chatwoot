# frozen_string_literal: true

module AnnotateRb
  module RouteAnnotator
    autoload :Annotator, "annotate_rb/route_annotator/annotator"
    autoload :Helper, "annotate_rb/route_annotator/helper"
    autoload :HeaderGenerator, "annotate_rb/route_annotator/header_generator"
    autoload :BaseProcessor, "annotate_rb/route_annotator/base_processor"
    autoload :AnnotationProcessor, "annotate_rb/route_annotator/annotation_processor"
    autoload :RemovalProcessor, "annotate_rb/route_annotator/removal_processor"
  end
end
