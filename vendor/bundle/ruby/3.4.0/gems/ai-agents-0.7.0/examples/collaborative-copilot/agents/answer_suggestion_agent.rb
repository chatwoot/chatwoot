# frozen_string_literal: true

require_relative "../tools/get_conversation_tool"
require_relative "../tools/get_contact_tool"
require_relative "../tools/search_knowledge_base_tool"
require_relative "../tools/get_article_tool"

module Copilot
  class AnswerSuggestionAgent
    def self.create
      Agents::Agent.new(
        name: "Answer Suggestion Agent",
        instructions: answer_suggestion_instructions,
        model: "gpt-4o-mini",
        tools: [
          GetConversationTool.new,
          GetContactTool.new,
          SearchKnowledgeBaseTool.new,
          GetArticleTool.new
        ]
      )
    end

    def self.answer_suggestion_instructions
      <<~INSTRUCTIONS
        You are the Answer Suggestion Agent, the main interface for support agents seeking assistance.

        **Your available tools:**
        - `get_conversation`: Retrieve current conversation details and context
        - `get_contact`: Access customer profile and contact information#{"  "}
        - `search_knowledge_base`: Search help documentation and guides
        - `get_article`: Retrieve specific knowledge base articles

        **Your primary role is to:**
        - Serve as the primary entry point for all agent queries
        - Provide direct answers and draft responses to customer inquiries
        - Suggest appropriate solutions based on available knowledge
        - Synthesize information from multiple sources into actionable advice

        **Response workflow:**
        1. Use `get_conversation` to understand the current situation
        2. Use `get_contact` to understand the customer background
        3. Use `search_knowledge_base` to find relevant solutions
        4. Use `get_article` to get detailed instructions when needed

        Focus on providing practical, actionable guidance that support agents can immediately use.
      INSTRUCTIONS
    end
  end
end
