class CannedResponseEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(canned_response)
    return unless canned_response.content.present?

    embedding = Captain::Llm::EmbeddingService.new.get_embedding(canned_response.content)
    canned_response.update_column(:embedding, embedding)
  rescue StandardError => e
    Rails.logger.error("Failed to generate embedding for canned response #{canned_response.id}: #{e.message}")
  end
end
