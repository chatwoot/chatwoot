# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    module AnnotatedFile
      autoload :Generator, "annotate_rb/model_annotator/annotated_file/generator"
      autoload :Updater, "annotate_rb/model_annotator/annotated_file/updater"
    end
  end
end
