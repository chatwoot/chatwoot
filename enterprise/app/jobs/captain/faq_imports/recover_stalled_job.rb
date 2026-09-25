class Captain::FaqImports::RecoverStalledJob < ApplicationJob
  queue_as :low

  PROCESS_ROWS = :process_rows

  def perform(faq_import, recovery_claimed_at)
    recovery = recovery_action(faq_import, recovery_claimed_at)
    return if recovery.nil?

    return Captain::FaqImports::ProcessJob.perform_later(faq_import) if recovery == PROCESS_ROWS
    return faq_import.complete_if_ready! if recovery.empty?

    recover_embeddings(faq_import, recovery)
  end

  private

  def recovery_action(faq_import, recovery_claimed_at)
    faq_import.with_lock do
      return unless faq_import.recovery_claim_current?(recovery_claimed_at)

      faq_import.rows_processed? ? pending_response_ids(faq_import) : PROCESS_ROWS
    end
  end

  def pending_response_ids(faq_import)
    faq_import.rows.filter_map do |row|
      row['response_id'] if row['embedding_state'] == Captain::FaqImport::EMBEDDING_STATES[:pending]
    end
  end

  def recover_embeddings(faq_import, response_ids)
    responses = faq_import.assistant.responses.where(id: response_ids).index_by(&:id)

    response_ids.each do |response_id|
      response = responses[response_id.to_i]
      if response.blank?
        faq_import.mark_embedding!(response_id, success: false)
      elsif response.embedding.present?
        faq_import.mark_embedding!(response.id, success: true)
      else
        Captain::Llm::UpdateEmbeddingJob.perform_later(response.id, "#{response.question}: #{response.answer}", faq_import)
      end
    end
  end
end
