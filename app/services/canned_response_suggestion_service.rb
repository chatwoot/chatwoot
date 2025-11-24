# Service to suggest relevant canned responses based on conversation context
# Uses semantic similarity search with vector embeddings

class CannedResponseSuggestionService
  def initialize(conversation)
    @conversation = conversation
    @account = conversation.account
  end

  def suggest_responses(limit: 5)
    context = build_conversation_context
    return [] if context.blank?

    # Get semantically similar canned responses
    suggestions = @account.canned_responses
                          .where.not(embedding: nil)
                          .semantic_search(context, limit: limit)

    format_suggestions(suggestions)
  rescue StandardError => e
    Rails.logger.error("Failed to generate canned response suggestions: #{e.message}")
    []
  end

  private

  def build_conversation_context
    # Get the last few messages to understand context
    recent_messages = @conversation.messages
                                   .incoming
                                   .order(created_at: :desc)
                                   .limit(3)
                                   .pluck(:content)

    # Combine messages into a single context string
    recent_messages.reverse.join(' ')
  end

  def format_suggestions(canned_responses)
    canned_responses.map do |response|
      {
        id: response.id,
        short_code: response.short_code,
        content: response.content,
        similarity_score: response.neighbor_distance ? (1 - response.neighbor_distance).round(3) : nil
      }
    end
  end
end
