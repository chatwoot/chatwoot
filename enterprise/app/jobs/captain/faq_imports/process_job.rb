class Captain::FaqImports::ProcessJob < ApplicationJob
  queue_as :low

  retry_on StandardError, wait: 5.seconds, attempts: 3 do |job, error|
    faq_import = job.arguments.first
    faq_import.fail!(error.message)
    ChatwootExceptionTracker.new(error, account: faq_import.account).capture_exception
  end

  discard_on ActiveJob::DeserializationError

  def perform(faq_import)
    return unless faq_import.preparing?

    process_rows(faq_import)
    faq_import.complete_if_ready!
  end

  private

  def process_rows(faq_import)
    faq_import.with_lock do
      return unless faq_import.preparing?
      return if faq_import.rows_processed?

      rows = faq_import.rows.deep_dup
      counts = { created: 0, overwritten: 0, skipped: 0 }
      existing_faqs = existing_faqs_by_question(faq_import.assistant)

      rows.each do |row|
        process_row(row, faq_import, existing_faqs, counts)
      end

      faq_import.update!(
        rows: rows,
        created_count: counts[:created],
        overwritten_count: counts[:overwritten],
        skipped_count: counts[:skipped]
      )
    end
  end

  def process_row(row, faq_import, existing_faqs, counts)
    return skip_row(counts) unless Captain::FaqImport::IMPORTABLE_ROW_STATES.include?(row['state'])
    return process_existing_row(row, faq_import, counts) if row['state'] == Captain::FaqImport::ROW_STATES[:existing]

    existing = existing_faqs[row['normalized_question']]
    return skip_row(counts) if existing.present?

    existing_faqs[row['normalized_question']] = create_faq(row, faq_import)
    counts[:created] += 1
  end

  def process_existing_row(row, faq_import, counts)
    return skip_row(counts) unless row['resolution'] == Captain::FaqImport::RESOLUTIONS[:overwrite]

    response = faq_import.assistant.responses.find_by(id: row['existing_id'])
    return skip_row(counts) unless overwrite_faq(response, row, faq_import)

    counts[:overwritten] += 1
  end

  def skip_row(counts)
    counts[:skipped] += 1
  end

  def existing_faqs_by_question(assistant)
    assistant.responses.select(:id, :question, :answer).order(:id).each_with_object({}) do |faq, result|
      normalized_question = Captain::FaqImports::Parser.normalize(faq.question)
      result[normalized_question] ||= faq
    end
  end

  def create_faq(row, faq_import)
    response = faq_import.assistant.responses.new(
      account: faq_import.account,
      documentable: faq_import.user,
      question: row['question'],
      answer: row['answer'],
      embedding: nil
    )
    save_response(response, row, faq_import)
    response
  end

  def overwrite_faq(response, row, faq_import)
    return false if response.blank?

    response.lock!
    return false unless Captain::FaqImports::Parser.normalize(response.question) == row['normalized_question']
    return false unless response.answer == row['existing_answer']

    response.assign_attributes(
      question: row['question'],
      answer: row['answer'],
      documentable: faq_import.user,
      embedding: nil
    )
    save_response(response, row, faq_import)
    true
  rescue ActiveRecord::RecordNotFound
    false
  end

  def save_response(response, row, faq_import)
    response.faq_import_context = faq_import
    response.save!
    row['response_id'] = response.id
    row['embedding_state'] = Captain::FaqImport::EMBEDDING_STATES[:pending]
  end
end
