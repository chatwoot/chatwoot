class DataImports::Csv::Importer
  BATCH_SIZE = 100

  def initialize(data_import:, run_id: nil)
    @data_import = data_import
    @run_id = run_id || data_import.active_import_run_id
    @run_state = DataImports::RunState.new(data_import, @run_id)
  end

  def start!
    @run_state.start!
  end

  def import_contacts?
    true
  end

  def import_conversations?
    false
  end

  def contacts_completed?
    @data_import.cursor.dig('contacts', 'completed') == true
  end

  def cursor_for(_key)
    @data_import.cursor.dig('contacts', 'starting_after')
  end

  def import_contacts_page(**)
    @data_import.items.pending.order(:id).limit(BATCH_SIZE).each do |item|
      break unless process_item(item)
    end
    next_cursor = nil
    @run_state.with_lock do
      next_cursor = @data_import.items.pending.minimum(:id)
      @data_import.update!(cursor: @data_import.cursor.merge('contacts' => {
                                                               'starting_after' => next_cursor,
                                                               'completed' => next_cursor.nil?
                                                             }))
    end
    DataImports::Importer::PageResult.new(next_cursor: next_cursor)
  end

  def finish!
    @run_state.with_lock do
      return unless @data_import.items.pending.none?

      DataImports::Csv::RejectedRowsExporter.new(@data_import).perform
      current_stats = stats
      @data_import.update!(status: current_stats.dig('contacts', 'failed').positive? ? :completed_with_errors : :completed,
                           completed_at: Time.current, stats: current_stats,
                           processed_records: current_stats.dig('contacts', 'imported'))
      DataImports::Csv::NotificationJob.perform_later(@data_import)
    end
  end

  def fail!(error)
    @run_state.with_lock do
      message = if error.is_a?(CustomExceptions::DataImport::InvalidCsvError) || error.is_a?(CSV::MalformedCSVError)
                  error.message
                else
                  'The import could not finish. Resume the import to try again.'
                end
      @data_import.import_errors.create!(error_code: error.class.name, message: message, details: { kind: 'run_error', source_provider: 'csv' })
      @data_import.update!(status: :failed, last_error_at: Time.current, stats: stats)
      DataImports::Csv::NotificationJob.perform_later(@data_import)
    end
  end

  private

  def process_item(item)
    @run_state.with_lock do
      item.reload
      next true unless item.pending?

      begin
        DataImportItem.transaction(requires_new: true) do
          contact, outcome = DataImports::Csv::ContactWriter.new(@data_import.account, item.metadata.fetch('fields')).perform
          item.update!(status: :imported, chatwoot_record_type: 'Contact', chatwoot_record_id: contact.id,
                       attempt_count: item.attempt_count + 1, last_error_code: nil, last_error_message: nil,
                       metadata: item.metadata.merge('outcome' => outcome))
        end
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, CustomExceptions::DataImport::InvalidCsvError => e
        reject_item(item.reload, e)
      end
      record_progress(item)
      true
    end
  end

  def record_progress(item)
    progress = @data_import.stats.deep_dup
    contacts = progress['contacts'] ||= {}
    keys = item.imported? ? ['imported', item.metadata.fetch('outcome'), 'processed'] : %w[failed processed]
    keys.each { |key| contacts[key] = contacts.fetch(key, 0) + 1 }
    progress['errors'] = { 'count' => progress.dig('errors', 'count').to_i + (item.failed? ? 1 : 0) }
    @data_import.update!(stats: progress, processed_records: contacts.fetch('imported', 0), updated_at: Time.current)
  end

  def reject_item(item, error)
    message = error.is_a?(ActiveRecord::RecordNotUnique) ? 'A contact with these identifiers already exists.' : error.message
    item.update!(status: :failed, attempt_count: item.attempt_count + 1, last_error_code: error.class.name, last_error_message: message)
    @data_import.import_errors.create!(data_import_item: item, source_object_type: 'contact', source_object_id: item.source_object_id,
                                       error_code: error.class.name, message: message,
                                       details: { kind: 'failed', row_number: item.metadata.fetch('row_number'), source_provider: 'csv' })
  end

  def stats
    counts = @data_import.items.group(:status).count
    outcomes = @data_import.items.imported.group("metadata ->> 'outcome'").count
    imported = counts.fetch('imported', 0)
    failed = counts.fetch('failed', 0)
    skipped = counts.fetch('skipped', 0)
    { 'contacts' => { 'total' => @data_import.total_records, 'imported' => imported, 'created' => outcomes.fetch('created', 0),
                      'updated' => outcomes.fetch('updated', 0), 'failed' => failed, 'skipped' => skipped,
                      'processed' => imported + failed + skipped },
      'errors' => { 'count' => failed + @data_import.import_errors.non_skip_logs.count } }
  end
end
