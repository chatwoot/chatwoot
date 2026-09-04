class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  class ImportEmbeddingError < StandardError; end

  retry_on ImportEmbeddingError, wait: 3.seconds, attempts: 3 do |job, _error|
    job.send(:mark_import_embedding_failed)
  end

  def perform(record_or_id, content, faq_import = nil)
    record = resolve_record(record_or_id, faq_import)
    return faq_import.mark_embedding!(record_or_id, success: false) if record.blank?

    account_id = record.account_id
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(content)
    record.update!(embedding: embedding)
    faq_import&.mark_embedding!(record.id, success: true)
  rescue Captain::Llm::EmbeddingService::EmbeddingsError => e
    raise if faq_import.blank?

    raise ImportEmbeddingError, e.message
  end

  private

  def resolve_record(record_or_id, faq_import)
    return record_or_id if faq_import.blank?

    faq_import.assistant.responses.find_by(id: record_or_id)
  end

  def record_id(record_or_id)
    record_or_id.respond_to?(:id) ? record_or_id.id : record_or_id
  end

  def mark_import_embedding_failed
    record_or_id, _content, faq_import = arguments
    faq_import&.mark_embedding!(record_id(record_or_id), success: false)
  end
end
