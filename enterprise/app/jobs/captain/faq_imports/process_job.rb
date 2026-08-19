class Captain::FaqImports::ProcessJob < ApplicationJob
  queue_as :low

  def perform(faq_import)
    return unless faq_import.preparing?

    process_rows(faq_import)
    faq_import.finish_if_no_embeddings!
  rescue StandardError => e
    faq_import.fail!(e.message)
  ensure
    faq_import.source_file.purge if faq_import.source_file.attached?
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
    return skip_row(counts) unless %w[valid existing].include?(row['state'])
    return skip_row(counts) if row['state'] == 'existing' && row['resolution'] == 'skip'

    existing = existing_faqs[row['normalized_question']]
    if existing.present?
      process_existing_row(existing, row, faq_import, counts)
    else
      existing_faqs[row['normalized_question']] = create_faq(row, faq_import)
      counts[:created] += 1
    end
  end

  def process_existing_row(existing, row, faq_import, counts)
    return skip_row(counts) unless row['state'] == 'existing' && row['resolution'] == 'overwrite'

    overwrite_faq(existing, row, faq_import)
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
    response.lock!
    response.assign_attributes(
      question: row['question'],
      answer: row['answer'],
      documentable: faq_import.user,
      embedding: nil
    )
    save_response(response, row, faq_import)
  end

  def save_response(response, row, faq_import)
    response.faq_import_context = faq_import
    response.save!
    row['response_id'] = response.id
    row['embedding_state'] = 'pending'
  end
end
