class Captain::FaqImports::RecoverStalledJob < ApplicationJob
  queue_as :low

  def perform(faq_import)
    recovery = recovery_action(faq_import)
    return if recovery.nil?

    return Captain::FaqImports::ProcessJob.perform_later(faq_import) if recovery == :process_rows
    return faq_import.fail!('The import stopped before search preparation finished.') if recovery.empty?

    recover_embeddings(faq_import, recovery)
  end

  private

  def recovery_action(faq_import)
    faq_import.with_lock do
      return unless faq_import.stalled?

      action = faq_import.rows_processed? ? pending_response_ids(faq_import) : :process_rows
      faq_import.update!(updated_at: Time.current)
      action
    end
  end

  def pending_response_ids(faq_import)
    faq_import.rows.filter_map do |row|
      row['response_id'] if row['embedding_state'] == 'pending'
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
        Captain::Llm::UpdateEmbeddingJob.perform_later(response, "#{response.question}: #{response.answer}", faq_import)
      end
    end
  end
end
