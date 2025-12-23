module Twilio
  module REST
    class Bulkexports < BulkexportsBase
      ##
      # @param [String] resource_type The type of communication – Messages, Calls,
      #   Conferences, and Participants
      # @return [Twilio::REST::Bulkexports::V1::ExportInstance] if resource_type was passed.
      # @return [Twilio::REST::Bulkexports::V1::ExportList]
      def exports(resource_type=:unset)
        warn "exports is deprecated. Use v1.exports instead."
        self.v1.exports(resource_type)
      end

      ##
      # @param [String] resource_type The type of communication – Messages, Calls,
      #   Conferences, and Participants
      # @return [Twilio::REST::Bulkexports::V1::ExportConfigurationInstance] if resource_type was passed.
      # @return [Twilio::REST::Bulkexports::V1::ExportConfigurationList]
      def export_configuration(resource_type=:unset)
        warn "export_configuration is deprecated. Use v1.export_configuration instead."
        self.v1.export_configuration(resource_type)
      end
    end
  end
end