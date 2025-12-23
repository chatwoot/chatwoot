module Twilio
  module REST
    class Content < ContentBase
      ##
      # @param [String] sid The unique string that that we created to identify the
      #   Content resource.
      # @return [Twilio::REST::Content::V1::ContentInstance] if sid was passed.
      # @return [Twilio::REST::Content::V1::ContentList]
      def contents(sid=:unset)
        warn "contents is deprecated. Use v1.contents instead."
        self.v1.contents(sid)
      end
    end
  end
end