class DataImports::Intercom::ContactsPageJob < DataImports::Intercom::BaseJob
  def perform(data_import, starting_after = nil, run_id = nil)
    return if skip_import?(data_import, run_id)

    importer = importer_for(data_import, run_id)
    return enqueue_conversations_or_finish(data_import, importer, run_id) if importer.contacts_completed?

    result = importer.import_contacts_page(starting_after: starting_after)
    return if skip_import?(data_import, run_id)
    return self.class.perform_later(data_import, result.next_cursor, run_id) unless result.done?

    enqueue_conversations_or_finish(data_import, importer, run_id)
  rescue StandardError => e
    fail_unexpected_error(importer, e)
  end

  private

  def enqueue_conversations_or_finish(data_import, importer, run_id)
    if importer.import_conversations? && !importer.conversations_completed?
      DataImports::Intercom::ConversationsPageJob.perform_later(data_import, importer.cursor_for('conversations'), run_id)
    else
      importer.finish!
    end
  end
end
