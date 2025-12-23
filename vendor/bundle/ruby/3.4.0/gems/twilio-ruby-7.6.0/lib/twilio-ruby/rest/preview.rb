module Twilio
  module REST
    class Preview < PreviewBase
      ##
      # @param [String] sid Contains a 34 character string that uniquely identifies this
      #   Fleet resource.
      # @return [Twilio::REST::Preview::DeployedDevices::FleetInstance] if sid was passed.
      # @return [Twilio::REST::Preview::DeployedDevices::FleetList]
      def fleets(sid=:unset)
        warn "fleets is deprecated. Use deployed_devices.fleets instead."
        self.deployed_devices.fleets(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   AuthorizationDocument.
      # @return [Twilio::REST::Preview::HostedNumbers::AuthorizationDocumentInstance] if sid was passed.
      # @return [Twilio::REST::Preview::HostedNumbers::AuthorizationDocumentList]
      def authorization_documents(sid=:unset)
        warn "authorization_documents is deprecated. Use hosted_numbers.authorization_documents instead."
        self.hosted_numbers.authorization_documents(sid)
      end

      ##
      # @param [String] sid A 34 character string that uniquely identifies this
      #   HostedNumberOrder.
      # @return [Twilio::REST::Preview::HostedNumbers::HostedNumberOrderInstance] if sid was passed.
      # @return [Twilio::REST::Preview::HostedNumbers::HostedNumberOrderList]
      def hosted_number_orders(sid=:unset)
        warn "hosted_number_orders is deprecated. Use hosted_numbers.hosted_number_orders instead."
        self.hosted_numbers.hosted_number_orders(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the
      #   AvailableAddOn resource.
      # @return [Twilio::REST::Preview::Marketplace::AvailableAddOnInstance] if sid was passed.
      # @return [Twilio::REST::Preview::Marketplace::AvailableAddOnList]
      def available_add_ons(sid=:unset)
        warn "available_add_ons is deprecated. Use marketplace.available_add_ons instead."
        self.marketplace.available_add_ons(sid)
      end

      ##
      # @param [String] sid The unique string that we created to identify the
      #   InstalledAddOn resource. This Sid can also be found in the Console on that
      #   specific Add-ons page as the 'Available Add-on Sid'.
      # @return [Twilio::REST::Preview::Marketplace::InstalledAddOnInstance] if sid was passed.
      # @return [Twilio::REST::Preview::Marketplace::InstalledAddOnList]
      def installed_add_ons(sid=:unset)
        warn "installed_add_ons is deprecated. Use marketplace.installed_add_ons instead."
        self.marketplace.installed_add_ons(sid)
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Preview::Wireless::CommandInstance] if sid was passed.
      # @return [Twilio::REST::Preview::Wireless::CommandList]
      def commands(sid=:unset)
        warn "commands is deprecated. Use wireless.commands instead."
        self.wireless.commands(sid)
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Preview::Wireless::RatePlanInstance] if sid was passed.
      # @return [Twilio::REST::Preview::Wireless::RatePlanList]
      def rate_plans(sid=:unset)
        warn "rate_plans is deprecated. Use wireless.rate_plans instead."
        self.wireless.rate_plans(sid)
      end

      ##
      # @param [String] sid The sid
      # @return [Twilio::REST::Preview::Wireless::SimInstance] if sid was passed.
      # @return [Twilio::REST::Preview::Wireless::SimList]
      def sims(sid=:unset)
        warn "sims is deprecated. Use wireless.sims instead."
        self.wireless.sims(sid)
      end
    end
  end
end
