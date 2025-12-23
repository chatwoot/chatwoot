# frozen_string_literal: true

module AnnotateRb
  # Not sure what this does just yet
  class EagerLoader
    class << self
      def call(options)
        options[:require].count > 0 && options[:require].each { |path| require path }

        if defined?(::Zeitwerk)
          # Delegate to Zeitwerk to load stuff as needed
          #   (Supports both Rails and non-Rails applications)
        elsif defined?(::Rails::Application)
          klass = ::Rails::Application.send(:subclasses).first
          klass.eager_load!
        else
          model_files = ModelAnnotator::ModelFilesGetter.call(options)
          model_files&.each do |model_file|
            require File.join(*model_file)
          end
        end
      end
    end
  end
end
