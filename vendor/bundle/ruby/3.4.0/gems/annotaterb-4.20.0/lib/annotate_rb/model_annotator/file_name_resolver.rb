# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class FileNameResolver
      class << self
        def call(filename_template, model_name, table_name)
          # e.g. with a model file name like "app/models/collapsed/example/test_model.rb"
          # and using a collapsed `model_name` such as "collapsed/test_model"
          model_name_without_namespace = model_name.split("/").last

          filename_template
            .gsub("%MODEL_NAME%", model_name)
            .gsub("%MODEL_NAME_WITHOUT_NS%", model_name_without_namespace)
            .gsub("%PLURALIZED_MODEL_NAME%", model_name.pluralize)
            .gsub("%TABLE_NAME%", table_name || model_name.pluralize)
        end
      end
    end
  end
end
