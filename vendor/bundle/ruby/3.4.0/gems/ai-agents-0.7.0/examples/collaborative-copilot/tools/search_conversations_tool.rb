# frozen_string_literal: true

require "json"

module Copilot
  # Tool for searching through conversation history to find similar cases
  class SearchConversationsTool < Agents::Tool
    description "Search past conversations for similar cases and resolutions"
    param :query, type: "string", desc: "Search terms (keywords, tags, or issue description)"
    param :contact_id, type: "string", desc: "Optional: limit search to specific contact", required: false

    def perform(_tool_context, query:, contact_id: nil)
      data_file = File.join(__dir__, "../data/conversations.json")
      return "Conversations database unavailable" unless File.exist?(data_file)

      begin
        conversations = JSON.parse(File.read(data_file))
        query_text = query.downcase
        matches = []

        conversations.each do |conv_id, conversation|
          # Skip if contact_id filter is specified and doesn't match
          next if contact_id && conversation["contact_id"] != contact_id.upcase

          # Simple keyword matching
          text_to_search = [
            conversation["subject"],
            conversation["tags"].join(" "),
            conversation["messages"].map { |m| m["content"] }.join(" "),
            conversation["resolution"]
          ].compact.join(" ").downcase

          next unless text_to_search.include?(query_text)

          matches << {
            conversation_id: conv_id,
            subject: conversation["subject"],
            status: conversation["status"],
            tags: conversation["tags"],
            resolution: conversation["resolution"]
          }
        end

        if matches.empty?
          "No similar conversations found for: #{query}"
        else
          JSON.pretty_generate({ query: query, conversations: matches })
        end
      rescue StandardError => e
        "Error searching conversations: #{e.message}"
      end
    end
  end
end
