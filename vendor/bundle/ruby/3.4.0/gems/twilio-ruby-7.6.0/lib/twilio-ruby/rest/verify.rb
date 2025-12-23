module Twilio
  module REST
    class Verify < VerifyBase
      ##
      # @param [form.FormTypes] form_type The Type of this Form. Currently only
      #   `form-push` is supported.
      # @return [Twilio::REST::Verify::V2::FormInstance] if form_type was passed.
      # @return [Twilio::REST::Verify::V2::FormList]
      def forms(form_type=:unset)
        warn "forms is deprecated. Use v2.forms instead."
        self.v2.forms(form_type)
      end

      ##
      # @param [String] phone_number The phone number in SafeList.
      # @return [Twilio::REST::Verify::V2::SafelistInstance] if phone_number was passed.
      # @return [Twilio::REST::Verify::V2::SafelistList]
      def safelist(phone_number=:unset)
        warn "safelist is deprecated. Use v2.safelist instead."
        self.v2.safelist(phone_number)
      end

      ##
      # @param [String] sid The unique string that we created to identify the Service
      #   resource.
      # @return [Twilio::REST::Verify::V2::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Verify::V2::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v2.services instead."
        self.v2.services(sid)
      end

      ##
      # @param [String] sid The SID that uniquely identifies the verification attempt
      #   resource.
      # @return [Twilio::REST::Verify::V2::VerificationAttemptInstance] if sid was passed.
      # @return [Twilio::REST::Verify::V2::VerificationAttemptList]
      def verification_attempts(sid=:unset)
        warn "verification_attempts is deprecated. Use v2.verification_attempts instead."
        self.v2.verification_attempts(sid)
      end

      ##
      # @return [Twilio::REST::Verify::V2::VerificationAttemptsSummaryInstance]
      def verification_attempts_summary
        warn "verification_attempts_summary is deprecated. Use v2.verification_attempts_summary instead."
        self.v2.verification_attempts_summary()
      end

      ##
      # @return [Twilio::REST::Verify::V2::TemplateInstance]
      def templates
        warn "templates is deprecated. Use v2.templates instead."
        self.v2.templates()
      end
    end
  end
end