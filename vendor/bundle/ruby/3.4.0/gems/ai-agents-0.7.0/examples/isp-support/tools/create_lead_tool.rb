# frozen_string_literal: true

module ISPSupport
  # Tool for creating sales leads in the CRM system.
  class CreateLeadTool < Agents::Tool
    description "Create a new sales lead with customer information"
    param :name, type: "string", desc: "Customer's full name"
    param :email, type: "string", desc: "Customer's email address"
    param :desired_plan, type: "string", desc: "Plan the customer is interested in"

    def perform(tool_context, name:, email:, desired_plan:)
      # Store lead information in state for follow-up
      tool_context.state[:lead_name] = name
      tool_context.state[:lead_email] = email
      tool_context.state[:desired_plan] = desired_plan
      tool_context.state[:lead_created_at] = Time.now.iso8601

      # Check if we have existing customer info from CRM lookup
      if tool_context.state[:customer_id]
        existing_customer = tool_context.state[:customer_name]
        "Lead created for existing customer #{existing_customer} (#{email}) " \
        "interested in upgrading to #{desired_plan} plan. Sales team will contact within 24 hours."
      else
        "Lead created for #{name} (#{email}) interested in #{desired_plan} plan. " \
        "Sales team will contact within 24 hours."
      end
    end
  end
end
