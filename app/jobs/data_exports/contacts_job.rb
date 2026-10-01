class DataExports::ContactsJob < ApplicationJob
  queue_as :low
  BATCH_SIZE = 1000

  def perform(data_export, run_id)
    @data_export = data_export
    @run_id = run_id
    return unless claim_export

    selection = DataExports::ContactSelection.new(account: data_export.account, user: data_export.initiated_by, options: data_export.export_options)
    contacts = selection.contacts
    contacts = contacts.where('contacts.id <= ?', contacts.maximum(:id) || 0)
    total = contacts.count
    data_export.with_lock { data_export.update!(total_records: total) if owned? }
    Tempfile.create(['contacts-export', '.csv']) do |file|
      write_csv(file, contacts, selection.columns)
      publish(file) if owned?
    end
  rescue StandardError
    fail_export
    raise
  end

  private

  def fail_export
    @data_export&.with_lock do
      if owned?
        @data_export.update!(status: :failed, completed_at: Time.current,
                             error_message: 'The export could not finish. Run the export again to retry.')
      end
    end
  end

  def claim_export
    @data_export.with_lock do
      next false unless @data_export.pending? && @data_export.active_run_id == @run_id

      if @data_export.requester_authorized?
        @data_export.update!(status: :processing, started_at: Time.current)
      else
        @data_export.update!(status: :failed, completed_at: Time.current, error_message: 'The requesting user no longer has export access.')
        false
      end
    end
  end

  def owned?
    @data_export.processing? && @data_export.active_run_id == @run_id
  end

  def write_csv(file, contacts, columns)
    file.write("\uFEFF")
    csv = CSVSafe.new(file)
    csv << columns
    contacts.reorder(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      write_batch(csv, batch, columns)
      continuing = @data_export.with_lock do
        next false unless owned?

        raise Pundit::NotAuthorizedError unless @data_export.requester_authorized?

        @data_export.update!(processed_records: @data_export.processed_records + batch.size)
      end
      break unless continuing
    end
    file.flush
    file.rewind
  end

  def write_batch(csv, batch, columns)
    labels = columns.include?('labels') ? labels_for(batch) : {}
    batch.each do |contact|
      csv << columns.map { |column| column == 'labels' ? labels.fetch(contact.id, []).join(',') : contact.public_send(column) }
    end
  end

  def labels_for(batch)
    ActsAsTaggableOn::Tagging.joins(:tag)
                             .where(context: 'labels', taggable_type: 'Contact', taggable_id: batch.map(&:id))
                             .where(tags: { name: @data_export.account.labels.select(:title) })
                             .pluck(:taggable_id, 'tags.name').group_by(&:first).transform_values { |rows| rows.map(&:last) }
  end

  def publish(file)
    blob = ActiveStorage::Blob.create_and_upload!(io: file, filename: "contacts-#{@data_export.id}.csv", content_type: 'text/csv')
    @data_export.with_lock do
      next unless owned?

      raise Pundit::NotAuthorizedError unless @data_export.requester_authorized?

      @data_export.export_file.attach(blob)
      @data_export.update!(status: :completed, completed_at: Time.current, total_records: @data_export.processed_records)
      DataExports::NotificationJob.perform_later(@data_export)
    end
  ensure
    blob&.purge_later if blob && !blob.attachments.exists?
  end
end
