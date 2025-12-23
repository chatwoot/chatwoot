# frozen_string_literal: true

require "securerandom"

module ISPSupport
  # Tool for creating checkout links for new service subscriptions.
  class CreateCheckoutTool < Agents::Tool
    description "Create a secure checkout link for a service plan"
    param :plan_name, type: "string", desc: "Name of the plan to purchase"

    def perform(_tool_context, plan_name:)
      session_id = SecureRandom.hex(8)
      "https://checkout.isp.com/#{session_id}"
    end
  end
end
