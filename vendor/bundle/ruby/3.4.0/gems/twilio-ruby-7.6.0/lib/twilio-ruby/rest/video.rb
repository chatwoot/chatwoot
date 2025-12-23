module Twilio
  module REST
    class Video < VideoBase
      ##
      # @param [String] sid The unique string that we created to identify the
      #   Composition resource.
      # @return [Twilio::REST::Video::V1::CompositionInstance] if sid was passed.
      # @return [Twilio::REST::Video::V1::CompositionList]
      def compositions(sid=:unset)
        warn "compositions is deprecated. Use v1.compositions instead."
        self.v1.compositions(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the
      #   CompositionHook resource.
      # @return [Twilio::REST::Video::V1::CompositionHookInstance] if sid was passed.
      # @return [Twilio::REST::Video::V1::CompositionHookList]
      def composition_hooks(sid=:unset)
        warn "composition_hooks is deprecated. Use v1.composition_hooks instead."
        self.v1.composition_hooks(sid)
      end

      ##
      # @return [Twilio::REST::Video::V1::CompositionSettingsInstance]
      def composition_settings
        warn "composition_settings is deprecated. Use v1.composition_settings instead."
        self.v1.composition_settings()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Recording
      #   resource.
      # @return [Twilio::REST::Video::V1::RecordingInstance] if sid was passed.
      # @return [Twilio::REST::Video::V1::RecordingList]
      def recordings(sid=:unset)
        warn "recordings is deprecated. Use v1.recordings instead."
        self.v1.recordings(sid)
      end

      ##
      # @return [Twilio::REST::Video::V1::RecordingSettingsInstance]
      def recording_settings
        warn "recording_settings is deprecated. Use v1.recording_settings instead."
        self.v1.recording_settings()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Room
      #   resource.
      # @return [Twilio::REST::Video::V1::RoomInstance] if sid was passed.
      # @return [Twilio::REST::Video::V1::RoomList]
      def rooms(sid=:unset)
        warn "rooms is deprecated. Use v1.rooms instead."
        self.v1.rooms(sid)
      end
    end
  end
end