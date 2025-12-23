# frozen_string_literal: true

require "generators/rack_mini_profiler/install_generator"

module RackProfiler
  module Generators
    class InstallGenerator < RackMiniProfiler::Generators::InstallGenerator
      source_root File.expand_path("../rack_mini_profiler/templates", __dir__)

      def create_initializer_file
        warn("bin/rails generate rack_profiler:install is deprecated. Please use rack_mini_profiler:install instead.")
        super
      end
    end
  end
end
