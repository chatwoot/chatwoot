module Twilio
  module REST
    class Conversations < ConversationsBase
      ##
      # @return [Twilio::REST::Conversations::V1::ConfigurationInstance]
      def configuration
        warn "configuration is deprecated. Use v1.configuration instead."
        self.v1.configuration()
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   resource.
      # @return [Twilio::REST::Conversations::V1::AddressConfigurationInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::AddressConfigurationList]
      def address_configurations(sid=:unset)
        warn "address_configurations is deprecated. Use v1.address_configurations instead."
        self.v1.address_configurations(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   resource.
      # @return [Twilio::REST::Conversations::V1::ConversationInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::ConversationList]
      def conversations(sid=:unset)
        warn "conversations is deprecated. Use v1.conversations instead."
        self.v1.conversations(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   resource.
      # @return [Twilio::REST::Conversations::V1::CredentialInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::CredentialList]
      def credentials(sid=:unset)
        warn "credentials is deprecated. Use v1.credentials instead."
        self.v1.credentials(sid)
      end

      ##
      # @return [Twilio::REST::Conversations::V1::ParticipantConversationInstance]
      def participant_conversations
        warn "participant_conversations is deprecated. Use v1.participant_conversations instead."
        self.v1.participant_conversations()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Role
      #   resource.
      # @return [Twilio::REST::Conversations::V1::RoleInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::RoleList]
      def roles(sid=:unset)
        warn "roles  is deprecated. Use v1.roles instead."
        self.v1.roles(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   resource.
      # @return [Twilio::REST::Conversations::V1::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v1.services instead."
        self.v1.services(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the User
      #   resource.
      # @return [Twilio::REST::Conversations::V1::UserInstance] if sid was passed.
      # @return [Twilio::REST::Conversations::V1::UserList]
      def users(sid=:unset)
        warn "users is deprecated. Use v1.users instead."
        self.v1.users(sid)
      end
    end
  end
end