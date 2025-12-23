# frozen_string_literal: true

module Zeitwerk
  class GemInflector < Inflector
    # @sig (String) -> void
    def initialize(root_file)
      namespace     = File.basename(root_file, ".rb")
      root_dir      = File.dirname(root_file)
      @version_file = File.join(root_dir, namespace, "version.rb")
    end

    # @sig (String, String) -> String
    def camelize(basename, abspath)
      abspath == @version_file ? "VERSION" : super
    end
  end
end
