# frozen_string_literal: true

require "web_console/testing/helper"
require "web_console/testing/fake_middleware"

module WebConsole
  module Testing
    # This class is to pre-compile 'templates/*.erb'.
    class ERBPrecompiler
      def initialize(path)
        @erb  = ERB.new(File.read(path))
        @view = FakeMiddleware.new(
          view_path: Helper.gem_root.join("lib/web_console/templates"),
        ).view
      end

      def build
        @erb.result(binding)
      end

      def method_missing(name, *args, &block)
        return super unless @view.respond_to?(name)
        @view.send(name, *args, &block)
      end
    end
  end
end
