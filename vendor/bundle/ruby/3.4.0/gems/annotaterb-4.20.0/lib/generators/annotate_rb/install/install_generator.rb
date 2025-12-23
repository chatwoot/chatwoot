# frozen_string_literal: true

require "annotate_rb"

module AnnotateRb
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      def install_hook_and_generate_defaults
        generate "annotate_rb:hook"
        generate "annotate_rb:config"
      end
    end
  end
end
