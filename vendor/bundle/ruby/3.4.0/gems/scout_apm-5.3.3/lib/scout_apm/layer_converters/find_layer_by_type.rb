# Scope is determined by the first Controller we hit.  Most of the time
# there will only be 1 anyway.  But if you have a controller that calls
# another controller method, we may pick that up:
#     def update
#       show
#       render :update
#     end

# This doesn't cache the negative result when searching for a controller / job,
# so that we can ask again later after more of the request has occurred and
# correctly find it.
module ScoutApm
  module LayerConverters
    class FindLayerByType
      def initialize(request)
        @request = request
      end

      def scope
        @scope ||= call(["Controller", "Job"])
      end

      def controller
        @controller ||= call(["Controller"])
      end

      def job
        @job ||= call(["Job"])
      end

      def queue
        @queue ||= call(["Queue"])
      end

      def call(layer_types)
        walker = DepthFirstWalker.new(@request.root_layer)
        walker.on {|l| return l if layer_types.include?(l.type) }
        walker.walk
      end
    end
  end
end
