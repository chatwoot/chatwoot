class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(record, content, faq_import = nil)
    account_id = record.account_id
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(content)
    record.update!(embedding: embedding)
    faq_import&.mark_embedding!(record.id, success: true)
  rescue StandardError
    faq_import&.mark_embedding!(record.id, success: false)
    raise if faq_import.blank?
  end
end
