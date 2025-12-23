module Twilio
  module REST
    class PreviewIam < PreviewIamBase
      def organizations( organization_sid = nil)
        @organizations ||= PreviewIam::Versionless.new(self).organization(organization_sid)
      end
    end
  end
end
