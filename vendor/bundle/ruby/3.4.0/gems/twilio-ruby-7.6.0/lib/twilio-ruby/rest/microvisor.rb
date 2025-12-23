module Twilio
  module REST
    class Microvisor < MicrovisorBase

      ##
      # @param [String] sid A 34-character string that uniquely identifies this App.
      # @return [Twilio::REST::Microvisor::V1::AppInstance] if sid was passed.
      # @return [Twilio::REST::Microvisor::V1::AppList]
      def apps(sid=:unset)
        warn "apps is deprecated. Use v1.apps instead."
        self.v1.apps(sid)
      end

      ##
      # @param [String] sid A 34-character string that uniquely identifies this Device.
      # @return [Twilio::REST::Microvisor::V1::DeviceInstance] if sid was passed.
      # @return [Twilio::REST::Microvisor::V1::DeviceList]
      def devices(sid=:unset)
        warn "devices is deprecated. Use v1.devices instead."
        self.v1.devices(sid)
      end
    end
  end
end
