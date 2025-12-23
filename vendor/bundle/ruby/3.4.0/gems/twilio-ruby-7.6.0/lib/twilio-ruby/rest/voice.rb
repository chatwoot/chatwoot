module Twilio
  module REST
    class Voice < VoiceBase
      ##
      # @param [String] sid The call sid
      # @return [Twilio::REST::Voice::V1::ArchivedCallInstance] if sid was passed.
      # @return [Twilio::REST::Voice::V1::ArchivedCallList]
      def archived_calls(date=:unset, sid=:unset)
        warn "archived_calls is deprecated. Use v1.archived_calls instead."
        self.v1.archived_calls(date, sid)
      end

      ##
      # @param [String] sid The unique string that that we created to identify the BYOC
      #   Trunk resource.
      # @return [Twilio::REST::Voice::V1::ByocTrunkInstance] if sid was passed.
      # @return [Twilio::REST::Voice::V1::ByocTrunkList]
      def byoc_trunks(sid=:unset)
        warn "byoc_trunks is deprecated. Use v1.byoc_trunks instead."
        self.v1.byoc_trunks(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Connection
      #   Policy resource.
      # @return [Twilio::REST::Voice::V1::ConnectionPolicyInstance] if sid was passed.
      # @return [Twilio::REST::Voice::V1::ConnectionPolicyList]
      def connection_policies(sid=:unset)
        warn "connection_policies is deprecated. Use v1.connection_policies instead."
        self.v1.connection_policies(sid)
      end

      ##
      # @return [Twilio::REST::Voice::V1::DialingPermissionsInstance]
      def dialing_permissions
        warn "dialing_permissions is deprecated. Use v1.dialing_permissions instead."
        self.v1.dialing_permissions()
      end

      ##
      # @param [String] sid The unique string that we created to identify the IP Record
      #   resource.
      # @return [Twilio::REST::Voice::V1::IpRecordInstance] if sid was passed.
      # @return [Twilio::REST::Voice::V1::IpRecordList]
      def ip_records(sid=:unset)
        warn "ip_records is deprecated. Use v1.ip_records instead."
        self.v1.ip_records(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the IP Record
      #   resource.
      # @return [Twilio::REST::Voice::V1::SourceIpMappingInstance] if sid was passed.
      # @return [Twilio::REST::Voice::V1::SourceIpMappingList]
      def source_ip_mappings(sid=:unset)
        warn "source_ip_mappings is deprecated. Use v1.source_ip_mappings instead."
        self.v1.source_ip_mappings(sid)
      end
    end
  end
end