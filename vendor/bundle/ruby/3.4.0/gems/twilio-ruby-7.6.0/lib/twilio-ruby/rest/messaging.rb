module Twilio
  module REST
    class Messaging < MessagingBase
      ##
      # @param [String] sid The unique string to identify Brand Registration.
      # @return [Twilio::REST::Messaging::V1::BrandRegistrationInstance] if sid was passed.
      # @return [Twilio::REST::Messaging::V1::BrandRegistrationList]
      def brand_registrations(sid=:unset)
        warn "brand_registrations is deprecated. Use v1.brand_registrations instead."
        self.v1.brand_registrations(sid)
      end

      ##
      # @return [Twilio::REST::Messaging::V1::DeactivationsInstance]
      def deactivations
        warn "deactivations is deprecated. Use v1.deactivations instead."
        self.v1.deactivations()
      end

      ##
      # @param [String] domain_sid The unique string that we created to identify the
      #   Domain resource.
      # @return [Twilio::REST::Messaging::V1::DomainCertsInstance] if domain_sid was passed.
      # @return [Twilio::REST::Messaging::V1::DomainCertsList]
      def domain_certs(domain_sid=:unset)
        warn "domain_certs is deprecated. Use v1.domain_certs instead."
        self.v1.domain_certs(domain_sid)
      end

      ##
      # @param [String] domain_sid The unique string that we created to identify the
      #   Domain resource.
      # @return [Twilio::REST::Messaging::V1::DomainConfigInstance] if domain_sid was passed.
      # @return [Twilio::REST::Messaging::V1::DomainConfigList]
      def domain_config(domain_sid=:unset)
        warn "domain_config is deprecated. Use v1.domain_config instead."
        self.v1.domain_config(domain_sid)
      end

      ##
      # @return [Twilio::REST::Messaging::V1::ExternalCampaignInstance]
      def external_campaign
        warn "external_campaign is deprecated. Use v1.external_campaign instead."
        self.v1.external_campaign()
      end

      ##
      # @param [String] sid The unique string that we created to identify the Service
      #   resource.
      # @return [Twilio::REST::Messaging::V1::ServiceInstance] if sid was passed.
      # @return [Twilio::REST::Messaging::V1::ServiceList]
      def services(sid=:unset)
        warn "services is deprecated. Use v1.services instead."
        self.v1.services(sid)
      end

      ##
      # @param [String] sid The unique string to identify Tollfree Verification.
      # @return [Twilio::REST::Messaging::V1::TollfreeVerificationInstance] if sid was passed.
      # @return [Twilio::REST::Messaging::V1::TollfreeVerificationList]
      def tollfree_verifications(sid=:unset)
        warn "tollfree_verifications is deprecated. Use v1.tollfree_verifications instead."
        self.v1.tollfree_verifications(sid)
      end

      ##
      # @return [Twilio::REST::Messaging::V1::UsecaseInstance]
      def usecases
        warn "usecases is deprecated. Use v1.usecases instead."
        self.v1.usecases()
      end
    end
  end
end
