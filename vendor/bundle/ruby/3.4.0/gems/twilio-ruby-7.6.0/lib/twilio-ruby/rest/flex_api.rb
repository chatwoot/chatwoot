module Twilio
  module REST
    class FlexApi < FlexApiBase
      ##
      # @return [Twilio::REST::Flex_api::V1::AssessmentsInstance]
      def assessments
        warn "assessments is deprecated. Use v1.assessments instead."
        self.v1.assessments()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Channel
      #   resource.
      # @return [Twilio::REST::Flex_api::V1::ChannelInstance] if sid was passed.
      # @return [Twilio::REST::Flex_api::V1::ChannelList]
      def channel(sid=:unset)
        warn "channel is deprecated. Use v1.channel instead."
        self.v1.channel(sid)
      end

      ##
      # @return [Twilio::REST::Flex_api::V1::ConfigurationInstance]
      def configuration
        warn "configuration is deprecated. Use v1.configuration instead."
        self.v1.configuration()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Flex Flow
      #   resource.
      # @return [Twilio::REST::Flex_api::V1::FlexFlowInstance] if sid was passed.
      # @return [Twilio::REST::Flex_api::V1::FlexFlowList]
      def flex_flow(sid=:unset)
        warn "flex_flow is deprecated. Use v1.flex_flow instead."
        self.v1.flex_flow(sid)
      end

      ##
      # @return [Twilio::REST::Flex_api::V1::GoodDataInstance]
      def good_data
        warn "good_data is deprecated. Use v1.good_data instead."
        self.v1.good_data()
      end

      ##
      # @param [String] sid The unique string created by Twilio to identify an
      #   Interaction resource, prefixed with KD.
      # @return [Twilio::REST::Flex_api::V1::InteractionInstance] if sid was passed.
      # @return [Twilio::REST::Flex_api::V1::InteractionList]
      def interaction(sid=:unset)
        warn "interaction is deprecated. Use v1.interaction instead."
        self.v1.interaction(sid)
      end

      ##
      # @return [Twilio::REST::Flex_api::V1::UserRolesInstance]
      def user_roles
        warn "user_roles is deprecated. Use v1.user_roles instead."
        self.v1.user_roles()
      end

      ##
      # @param [String] sid The unique string that we created to identify the WebChannel
      #   resource.
      # @return [Twilio::REST::Flex_api::V1::WebChannelInstance] if sid was passed.
      # @return [Twilio::REST::Flex_api::V1::WebChannelList]
      def web_channel(sid=:unset)
        warn "web_channel is deprecated. Use v1.web_channel instead."
        self.v1.web_channel(sid)
      end
    end
  end
end