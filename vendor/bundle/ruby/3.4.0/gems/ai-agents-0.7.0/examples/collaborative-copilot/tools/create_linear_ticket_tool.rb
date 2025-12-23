# frozen_string_literal: true

require "json"

module Copilot
  # Tool for creating Linear tickets for engineering issues
  class CreateLinearTicketTool < Agents::Tool
    description "Create a Linear ticket for engineering issues or feature requests"
    param :title, type: "string", desc: "Title of the issue"
    param :description, type: "string", desc: "Detailed description of the issue"
    param :priority, type: "string", desc: "Priority level (low, medium, high)"
    param :assignee, type: "string", desc: "Optional: email of person to assign to", required: false
    param :labels, type: "string", desc: "Comma-separated labels (e.g., bug,api,production)"

    def perform(tool_context, title:, description:, priority: "medium", assignee: nil, labels: "")
      # Generate a ticket ID
      ticket_id = "ENG-#{rand(100..999)}"

      # Parse labels
      label_array = labels.split(",").map(&:strip).reject(&:empty?)
      label_array = ["support-request"] if label_array.empty?

      # Create ticket data
      {
        id: ticket_id,
        title: title,
        description: description,
        status: "backlog",
        priority: priority.downcase,
        assignee: assignee,
        labels: label_array,
        created_at: Time.now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        reporter: "support-agent"
      }

      # Store ticket info in shared state
      tool_context.state[:created_ticket_id] = ticket_id
      tool_context.state[:ticket_priority] = priority
      tool_context.state[:ticket_assignee] = assignee

      response = {
        success: true,
        ticket_id: ticket_id,
        title: title,
        status: "backlog",
        priority: priority,
        assignee: assignee,
        labels: label_array,
        url: "https://linear.app/company/issue/#{ticket_id}",
        message: "Successfully created Linear ticket #{ticket_id}"
      }

      JSON.pretty_generate(response)
    rescue StandardError => e
      "Error creating Linear ticket: #{e.message}"
    end
  end
end
