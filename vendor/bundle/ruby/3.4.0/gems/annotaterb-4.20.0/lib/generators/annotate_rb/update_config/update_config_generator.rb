# frozen_string_literal: true

require "annotate_rb"

module AnnotateRb
  module Generators
    class UpdateConfigGenerator < ::Rails::Generators::Base
      def generate_config
        insert_into_file ::AnnotateRb::ConfigFinder::DOTFILE do
          ::AnnotateRb::ConfigGenerator.unset_config_defaults
        end
      end
    end
  end
end
