# frozen_string_literal: true

require "json"

module Copilot
  # Tool for retrieving contact/customer information
  class GetContactTool < Agents::Tool
    description "Get customer profile and contact information"
    param :contact_id, type: "string", desc: "ID of the contact to retrieve"

    def perform(tool_context, contact_id:)
      data_file = File.join(__dir__, "../data/contacts.json")
      return "Contacts database unavailable" unless File.exist?(data_file)

      begin
        contacts = JSON.parse(File.read(data_file))
        contact = contacts[contact_id.upcase]

        return "Contact not found" unless contact

        # Store contact data in shared state for other agents
        tool_context.state[:contact_name] = contact["name"]
        tool_context.state[:contact_email] = contact["email"]
        tool_context.state[:contact_company] = contact["company"]
        tool_context.state[:contact_plan] = contact["plan"]
        tool_context.state[:contact_satisfaction] = contact["satisfaction_score"]

        # Format contact information
        response = {
          id: contact["id"],
          name: contact["name"],
          email: contact["email"],
          phone: contact["phone"],
          company: contact["company"],
          plan: contact["plan"],
          account_status: contact["account_status"],
          created_at: contact["created_at"],
          last_login: contact["last_login"],
          total_conversations: contact["total_conversations"],
          satisfaction_score: contact["satisfaction_score"],
          tags: contact["tags"],
          notes: contact["notes"]
        }

        JSON.pretty_generate(response)
      rescue StandardError => e
        "Error retrieving contact: #{e.message}"
      end
    end
  end
end
