# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class ModelClassGetter
      class << self
        # Retrieve the classes belonging to the model names we're asked to process
        # Check for namespaced models in subdirectories as well as models
        # in subdirectories without namespacing.
        def call(file, options)
          use_zeitwerk = defined?(::Rails) && ::Rails.try(:autoloaders).try(:zeitwerk_enabled?)

          if use_zeitwerk
            klass = ZeitwerkClassGetter.call(file, options)
            return klass if klass
          end

          model_path = file.gsub(/\.rb$/, "")
          options[:model_dir].each { |dir| model_path = model_path.gsub(/^#{dir}/, "").gsub(/^\//, "") }

          begin
            get_loaded_model(model_path, file) || raise(BadModelFileError.new)
          rescue LoadError
            # this is for non-rails projects, which don't get Rails auto-require magic
            file_path = File.expand_path(file)
            if File.file?(file_path) && Kernel.require(file_path)
              retry
            elsif /\//.match?(model_path)
              model_path = model_path.split("/")[1..-1].join("/").to_s
              retry
            else
              raise
            end
          end
        end

        private

        # Retrieve loaded model class
        def get_loaded_model(model_path, file)
          loaded_model_class = get_loaded_model_by_path(model_path)
          return loaded_model_class if loaded_model_class

          # We cannot get loaded model when `model_path` is loaded by Rails
          # auto_load/eager_load paths. Try all possible model paths one by one.
          absolute_file = File.expand_path(file)
          model_paths =
            $LOAD_PATH.select { |path| absolute_file.include?(path) }
              .map { |path| absolute_file.sub(path, "").sub(/\.rb$/, "").sub(/^\//, "") }
          model_paths
            .map { |path| get_loaded_model_by_path(path) }
            .find { |loaded_model| !loaded_model.nil? }
        end

        # Retrieve loaded model class by path to the file where it's supposed to be defined.
        def get_loaded_model_by_path(model_path)
          ::ActiveSupport::Inflector.constantize(::ActiveSupport::Inflector.camelize(model_path))
        rescue StandardError, LoadError
          # Revert to the old way but it is not really robust
          ObjectSpace.each_object(::Class)
            .select do |c|
            Class === c && # note: we use === to avoid a bug in activesupport 2.3.14 OptionMerger vs. is_a?
              c.ancestors.respond_to?(:include?) && # to fix FactoryGirl bug, see https://github.com/ctran/annotate_models/pull/82
              c.ancestors.include?(::ActiveRecord::Base)
          end.detect { |c| ::ActiveSupport::Inflector.underscore(c.to_s) == model_path }
        end
      end
    end
  end
end
