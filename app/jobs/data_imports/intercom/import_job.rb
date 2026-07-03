class DataImports::Intercom::ImportJob < DataImports::Intercom::BaseJob
  def perform(data_import, run_id = nil)
    return if skip_import?(data_import, run_id)

    importer = importer_for(data_import, run_id)
    return unless importer.start!

    enqueue_next_stage(data_import, importer, run_id)
  rescue StandardError => e
    fail_unexpected_error(importer, e)
  end

  private

  def enqueue_next_stage(data_import, importer, run_id)
    if importer.import_contacts? && !importer.contacts_completed?
      DataImports::Intercom::ContactsPageJob.perform_later(data_import, importer.cursor_for('contacts'), run_id)
    elsif importer.import_conversations? && !importer.conversations_completed?
      DataImports::Intercom::ConversationsPageJob.perform_later(data_import, importer.cursor_for('conversations'), run_id)
    else
      importer.finish!
    end
  end
end
