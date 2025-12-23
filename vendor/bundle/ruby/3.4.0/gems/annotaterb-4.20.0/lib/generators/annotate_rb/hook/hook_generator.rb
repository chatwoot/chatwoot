# frozen_string_literal: true

require "annotate_rb"

module AnnotateRb
  module Generators
    class HookGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_hook_file
        copy_file "annotate_rb.rake", "lib/tasks/annotate_rb.rake"
      end
    end
  end
end
