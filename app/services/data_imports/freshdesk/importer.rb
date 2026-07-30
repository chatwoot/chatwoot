class DataImports::Freshdesk::Importer < DataImports::Importer
  InvalidMessagePayloadError = DataImports::Importer::InvalidMessagePayloadError
  ALREADY_IMPORTED_ERROR_CODE = DataImports::Freshdesk::Source::ALREADY_IMPORTED_ERROR_CODE
  SKIPPED_MESSAGE_ERROR_CODE = DataImports::Freshdesk::Source::SKIPPED_MESSAGE_ERROR_CODE
  TRUNCATED_PARTS_ERROR_CODE = DataImports::Freshdesk::Source::TRUNCATED_PARTS_ERROR_CODE

  def import_conversations_page(starting_after: cursor_for('conversations'))
    response = conversations_page(starting_after)
    checkpoint_ticket_page(response)
    update_stat_total('conversations', response['total_count']) if response['total_count'].present?
    import_conversation_summaries(response)
    return PageResult.new(next_cursor: nil) if import_stopped?

    reconcile_dirty_stats
    next_cursor = response.dig('pages', 'next', 'starting_after')
    update_cursor('conversations', next_cursor)
    PageResult.new(next_cursor: next_cursor)
  end

  private

  def checkpoint_ticket_page(response)
    current_cursor = response.dig('pages', 'current', 'starting_after')
    update_cursor('conversations', current_cursor) unless current_cursor == cursor_for('conversations')
  end

  def conversations_page(starting_after)
    @source.list_conversations(
      starting_after: cursor_for('conversations').presence || starting_after,
      per_page: @source.conversations_per_page
    )
  end

  def import_conversation_summaries(response)
    summaries = Array(response['data'] || response['conversations'])
    checkpoints = Array(response.dig('pages', 'checkpoints'))

    summaries.each_with_index do |conversation_summary, index|
      break if import_stopped?

      import_conversation_from_summary(conversation_summary)
      break if import_stopped?

      update_cursor('conversations', checkpoints.fetch(index)) if index < summaries.length - 1
    end
  end
end
