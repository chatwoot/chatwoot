# frozen_string_literal: true

require "json"

module Copilot
  # Tool for retrieving conversation details and context
  class GetConversationTool < Agents::Tool
    description "Get conversation details, messages, and context for analysis"
    param :conversation_id, type: "string", desc: "ID of the conversation to retrieve"

    def perform(tool_context, conversation_id:)
      data_file = File.join(__dir__, "../data/conversations.json")
      return "Conversations database unavailable" unless File.exist?(data_file)

      begin
        conversations = JSON.parse(File.read(data_file))
        conversation = conversations[conversation_id.upcase]

        return "Conversation not found" unless conversation

        # Store conversation data in shared state for other agents
        tool_context.state[:current_conversation_id] = conversation_id.upcase
        tool_context.state[:conversation_status] = conversation["status"]
        tool_context.state[:conversation_subject] = conversation["subject"]
        tool_context.state[:contact_id] = conversation["contact_id"]

        # Format conversation for analysis
        formatted_messages = conversation["messages"].map do |msg|
          "#{msg["role"].upcase} (#{msg["timestamp"]}): #{msg["content"]}"
        end

        response = {
          id: conversation["id"],
          subject: conversation["subject"],
          status: conversation["status"],
          contact_id: conversation["contact_id"],
          created_at: conversation["created_at"],
          message_count: conversation["messages"].length,
          tags: conversation["tags"],
          messages: formatted_messages
        }

        # Add resolution if available
        response[:resolution] = conversation["resolution"] if conversation["resolution"]
        response[:escalation_ticket] = conversation["escalation_ticket"] if conversation["escalation_ticket"]

        JSON.pretty_generate(response)
      rescue StandardError => e
        "Error retrieving conversation: #{e.message}"
      end
    end
  end
end
