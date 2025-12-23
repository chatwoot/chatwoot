# frozen_string_literal: true

require "json"

module Copilot
  # Tool for searching Linear issues for development context and bug reports
  class SearchLinearIssuesTool < Agents::Tool
    description "Search Linear issues for bug reports, feature requests, and development context"
    param :query, type: "string", desc: "Search terms (keywords, error messages, or feature descriptions)"
    param :status, type: "string", desc: "Optional: filter by status (backlog, in_progress, completed, resolved)",
                   required: false
    param :priority, type: "string", desc: "Optional: filter by priority (low, medium, high)", required: false

    def perform(_tool_context, query:, status: nil, priority: nil)
      data_file = File.join(__dir__, "../data/linear_issues.json")
      return "Linear issues database unavailable" unless File.exist__(data_file)

      begin
        linear_data = JSON.parse(File.read(data_file))
        issues = linear_data["issues"]
        query_text = query.downcase
        matches = []

        issues.each do |issue_id, issue|
          # Apply filters
          next if status && issue["status"] != status.downcase
          next if priority && issue["priority"] != priority.downcase

          # Simple keyword matching
          text_to_search = [
            issue["title"],
            issue["description"],
            issue["labels"].join(" "),
            issue["resolution"]
          ].compact.join(" ").downcase

          next unless text_to_search.include?(query_text)

          matches << {
            issue_id: issue_id,
            title: issue["title"],
            status: issue["status"],
            priority: issue["priority"],
            labels: issue["labels"],
            description: "#{issue["description"][0...200]}...",
            resolution: issue["resolution"]
          }
        end

        if matches.empty?
          "No Linear issues found for: #{query}"
        else
          JSON.pretty_generate({ query: query, issues: matches })
        end
      rescue StandardError => e
        "Error searching Linear issues: #{e.message}"
      end
    end
  end
end
