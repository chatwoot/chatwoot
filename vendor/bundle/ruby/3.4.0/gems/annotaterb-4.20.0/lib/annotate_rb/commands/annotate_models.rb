# frozen_string_literal: true

module AnnotateRb
  module Commands
    class AnnotateModels
      def call(options)
        puts "Annotating models"

        if options[:debug]
          puts "Running with debug mode, options:"
          pp options.to_h
        end

        # Eager load Models when we're annotating models
        AnnotateRb::EagerLoader.call(options)

        AnnotateRb::ModelAnnotator::Annotator.send(options[:target_action], options)
      end
    end
  end
end
