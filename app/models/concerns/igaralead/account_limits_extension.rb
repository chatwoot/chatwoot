# frozen_string_literal: true

module Igaralead::AccountLimitsExtension
  def usage_limits
    return super if hub_client_slug.blank? || !HubClient.configured?

    Igaralead::LimitEnforcementService.usage_limits(self)
  end
end
