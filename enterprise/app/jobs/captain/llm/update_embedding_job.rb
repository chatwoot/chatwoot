class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(record, content)
    account_id = record.respond_to?(:account_id) ? record.account_id : nil
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(content)
    record.update!(embedding: embedding)
  end
end
