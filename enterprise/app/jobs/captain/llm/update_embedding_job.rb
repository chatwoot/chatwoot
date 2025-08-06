class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(record, content)
    # Early return if record was deleted before job execution
    return unless record&.persisted?

    embedding = Captain::Llm::EmbeddingService.new.get_embedding(content)
    record.update!(embedding: embedding)
  end
end
