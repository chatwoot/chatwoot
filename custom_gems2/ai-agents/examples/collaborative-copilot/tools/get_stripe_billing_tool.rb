# frozen_string_literal: true

require "json"

module Copilot
  # Tool for retrieving Stripe billing information
  class GetStripeBillingTool < Agents::Tool
    description "Get customer billing information and payment history from Stripe"
    param :customer_email, type: "string", desc: "Customer email to look up billing info"

    def perform(tool_context, customer_email:)
      data_file = File.join(__dir__, "../data/stripe_billing.json")
      return "Stripe billing data unavailable" unless File.exist?(data_file)

      begin
        billing_data = JSON.parse(File.read(data_file))
        customer_data = billing_data[customer_email.downcase]

        return "No billing information found for #{customer_email}" unless customer_data

        # Store billing info in shared state
        tool_context.state[:stripe_customer_id] = customer_data["customer_id"]
        tool_context.state[:subscription_status] = customer_data["subscription_status"]
        tool_context.state[:current_plan] = customer_data["current_plan"]

        formatted_data = {
          customer_email: customer_email,
          stripe_customer_id: customer_data["customer_id"],
          subscription_status: customer_data["subscription_status"],
          current_plan: customer_data["current_plan"],
          monthly_amount: "$#{customer_data["monthly_amount"] / 100}",
          next_billing_date: customer_data["next_billing_date"],
          payment_method: customer_data["payment_method"],
          total_paid: "$#{customer_data["total_paid"] / 100}",
          recent_charges: customer_data["recent_charges"]
        }

        JSON.pretty_generate(formatted_data)
      rescue StandardError => e
        "Error retrieving billing information: #{e.message}"
      end
    end
  end
end
