module Twilio
  module REST
    class Supersim < SupersimBase
      ##
      # @param [String] sid The unique string that we created to identify the eSIM
      #   Profile resource.
      # @return [Twilio::REST::Supersim::V1::EsimProfileInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::EsimProfileList]
      def esim_profiles(sid=:unset)
        warn "esim_profiles is deprecated. Use v1.esim_profiles instead."
        self.v1.esim_profiles(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Fleet
      #   resource.
      # @return [Twilio::REST::Supersim::V1::FleetInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::FleetList]
      def fleets(sid=:unset)
        warn "fleets is deprecated. Use v1.fleets instead."
        self.v1.fleets(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the IP Command
      #   resource.
      # @return [Twilio::REST::Supersim::V1::IpCommandInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::IpCommandList]
      def ip_commands(sid=:unset)
        warn "ip_commands is deprecated. Use v1.ip_commands instead."
        self.v1.ip_commands(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Network
      #   resource.
      # @return [Twilio::REST::Supersim::V1::NetworkInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::NetworkList]
      def networks(sid=:unset)
        warn "networks is deprecated. Use v1.networks instead."
        self.v1.networks(sid)
      end

      ##
      # @param [String] sid The unique string that identifies the Network Access Profile
      #   resource.
      # @return [Twilio::REST::Supersim::V1::NetworkAccessProfileInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::NetworkAccessProfileList]
      def network_access_profiles(sid=:unset)
        warn "network_access_profiles is deprecated. Use v1.network_access_profiles instead."
        self.v1.network_access_profiles(sid)
      end

      ##
      # @return [Twilio::REST::Supersim::V1::SettingsUpdateInstance]
      def settings_updates
        warn "settings_updates is deprecated. Use v1.settings_updates instead."
        self.v1.settings_updates()
      end

      ##
      # @param [String] sid The unique string that identifies the Sim resource.
      # @return [Twilio::REST::Supersim::V1::SimInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::SimList]
      def sims(sid=:unset)
        warn "sims is deprecated. Use v1.sims instead."
        self.v1.sims(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the SMS
      #   Command resource.
      # @return [Twilio::REST::Supersim::V1::SmsCommandInstance] if sid was passed.
      # @return [Twilio::REST::Supersim::V1::SmsCommandList]
      def sms_commands(sid=:unset)
        warn "sms_commands is deprecated. Use v1.sms_commands instead."
        self.v1.sms_commands(sid)
      end

      ##
      # @return [Twilio::REST::Supersim::V1::UsageRecordInstance]
      def usage_records
        warn "usage_records is deprecated. Use v1.usage_records instead."
        self.v1.usage_records()
      end
    end
  end
end