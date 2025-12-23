# frozen_string_literal: true

require "annotate_rb"

module AnnotateRb
  module Generators
    class ConfigGenerator < ::Rails::Generators::Base
      def generate_config
        create_file ::AnnotateRb::ConfigFinder::DOTFILE do
          ::AnnotateRb::ConfigGenerator.default_config_yml
        end
      end
    end
  end
end
