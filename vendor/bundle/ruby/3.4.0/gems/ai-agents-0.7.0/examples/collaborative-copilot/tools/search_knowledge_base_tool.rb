# frozen_string_literal: true

require "json"

module Copilot
  # Tool for searching knowledge base articles and documentation
  class SearchKnowledgeBaseTool < Agents::Tool
    description "Search help documentation and knowledge base for solutions"
    param :query, type: "string", desc: "Search terms or keywords to find relevant articles"
    param :category, type: "string",
                     desc: "Optional: filter by category (troubleshooting, account, development, billing)", required: false

    def perform(_tool_context, query:, category: nil)
      data_file = File.join(__dir__, "../data/knowledge_base.json")
      return "Knowledge base unavailable" unless File.exist?(data_file)

      begin
        kb_data = JSON.parse(File.read(data_file))
        articles = kb_data["articles"]
        query_text = query.downcase
        matches = []

        articles.each do |article_id, article|
          # Skip if category filter is specified and doesn't match
          next if category && article["category"] != category.downcase

          # Simple keyword matching
          text_to_search = [
            article["title"],
            article["tags"].join(" "),
            article["content"]
          ].join(" ").downcase

          next unless text_to_search.include?(query_text)

          matches << {
            article_id: article_id,
            title: article["title"],
            category: article["category"],
            tags: article["tags"],
            content_preview: "#{article["content"][0...200]}..."
          }
        end

        if matches.empty?
          "No knowledge base articles found for: #{query}"
        else
          JSON.pretty_generate({ query: query, articles: matches })
        end
      rescue StandardError => e
        "Error searching knowledge base: #{e.message}"
      end
    end
  end
end
