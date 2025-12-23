module Shoulda
  module Matchers
    # @private
    module Routing
      def route(method, path, port: nil)
        ActionController::RouteMatcher.new(self, method, path, port: port)
      end
    end
  end
end
