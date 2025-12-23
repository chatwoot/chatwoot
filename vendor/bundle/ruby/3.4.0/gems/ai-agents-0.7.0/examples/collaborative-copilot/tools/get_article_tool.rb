# frozen_string_literal: true

require "json"

module Copilot
  # Tool for retrieving specific knowledge base articles by ID
  class GetArticleTool < Agents::Tool
    description "Get the full content of a specific knowledge base article"
    param :article_id, type: "string", desc: "ID of the article to retrieve (e.g., ART-001)"

    def perform(tool_context, article_id:)
      data_file = File.join(__dir__, "../data/knowledge_base.json")
      return "Knowledge base unavailable" unless File.exist?(data_file)

      begin
        kb_data = JSON.parse(File.read(data_file))
        article = kb_data["articles"][article_id.upcase]

        return "Article not found" unless article

        # Store article data in shared state for reference
        tool_context.state[:last_article_id] = article_id.upcase
        tool_context.state[:last_article_category] = article["category"]

        response = {
          id: article_id.upcase,
          title: article["title"],
          category: article["category"],
          content: article["content"],
          tags: article["tags"],
          created_at: article["created_at"],
          updated_at: article["updated_at"]
        }

        JSON.pretty_generate(response)
      rescue StandardError => e
        "Error retrieving article: #{e.message}"
      end
    end
  end
end
