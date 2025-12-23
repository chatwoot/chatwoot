# frozen_string_literal: true

require "json"

module Copilot
  # Tool for searching contacts to find patterns and related customers
  class SearchContactsTool < Agents::Tool
    description "Search contacts to find patterns, related customers, or specific profiles"
    param :query, type: "string", desc: "Search terms (name, email, company, or tags)"
    param :plan, type: "string", desc: "Optional: filter by plan type (Basic, Pro, Enterprise)", required: false

    def perform(_tool_context, query:, plan: nil)
      data_file = File.join(__dir__, "../data/contacts.json")
      return "Contacts database unavailable" unless File.exist?(data_file)

      begin
        contacts = JSON.parse(File.read(data_file))
        query_text = query.downcase
        matches = []

        contacts.each do |contact_id, contact|
          # Skip if plan filter is specified and doesn't match
          next if plan && contact["plan"].downcase != plan.downcase

          # Simple keyword matching
          text_to_search = [
            contact["name"],
            contact["email"],
            contact["company"],
            contact["tags"].join(" "),
            contact["notes"]
          ].join(" ").downcase

          next unless text_to_search.include?(query_text)

          matches << {
            contact_id: contact_id,
            name: contact["name"],
            email: contact["email"],
            company: contact["company"],
            plan: contact["plan"],
            tags: contact["tags"],
            satisfaction_score: contact["satisfaction_score"]
          }
        end

        if matches.empty?
          "No contacts found for: #{query}"
        else
          JSON.pretty_generate({ query: query, contacts: matches })
        end
      rescue StandardError => e
        "Error searching contacts: #{e.message}"
      end
    end
  end
end
