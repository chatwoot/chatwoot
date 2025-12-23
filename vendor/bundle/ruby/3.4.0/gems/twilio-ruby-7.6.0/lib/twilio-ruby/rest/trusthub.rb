module Twilio
  module REST
    class Trusthub < TrusthubBase
      ##
      # @param [String] sid The unique string that we created to identify the
      #   Customer-Profile resource.
      # @return [Twilio::REST::Trusthub::V1::CustomerProfilesInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::CustomerProfilesList]
      def customer_profiles(sid=:unset)
        warn "customer_profiles is deprecated. Use v1.customer_profiles instead."
        self.v1.customer_profiles(sid)
      end

      ##
      # @param [String] sid The unique string created by Twilio to identify the End User
      #   resource.
      # @return [Twilio::REST::Trusthub::V1::EndUserInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::EndUserList]
      def end_users(sid=:unset)
        warn "end_users is deprecated. Use v1.end_users instead."
        self.v1.end_users(sid)
      end

      ##
      # @param [String] sid The unique string that identifies the End-User Type
      #   resource.
      # @return [Twilio::REST::Trusthub::V1::EndUserTypeInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::EndUserTypeList]
      def end_user_types(sid=:unset)
        warn "end_user_types is deprecated. Use v1.end_user_types instead."
        self.v1.end_user_types(sid)
      end

      ##
      # @param [String] sid The unique string that identifies the Policy resource.
      # @return [Twilio::REST::Trusthub::V1::PoliciesInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::PoliciesList]
      def policies(sid=:unset)
        warn "policies is deprecated. Use v1.policies instead."
        self.v1.policies(sid)
      end

      ##
      # @param [String] sid The unique string created by Twilio to identify the
      #   Supporting Document resource.
      # @return [Twilio::REST::Trusthub::V1::SupportingDocumentInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::SupportingDocumentList]
      def supporting_documents(sid=:unset)
        warn "supporting_documents is deprecated. Use v1.supporting_documents instead."
        self.v1.supporting_documents(sid)
      end

      ##
      # @param [String] sid The unique string that identifies the Supporting Document
      #   Type resource.
      # @return [Twilio::REST::Trusthub::V1::SupportingDocumentTypeInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::SupportingDocumentTypeList]
      def supporting_document_types(sid=:unset)
        warn "supporting_document_types is deprecated. Use v1.supporting_document_types instead."
        self.v1.supporting_document_types(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the
      #   Customer-Profile resource.
      # @return [Twilio::REST::Trusthub::V1::TrustProductsInstance] if sid was passed.
      # @return [Twilio::REST::Trusthub::V1::TrustProductsList]
      def trust_products(sid=:unset)
        warn "trust_products is deprecated. Use v1.trust_products instead."
        self.v1.trust_products(sid)
      end
    end
  end
end