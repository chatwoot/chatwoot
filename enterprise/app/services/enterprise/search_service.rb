module Enterprise::SearchService
  def advanced_search
    where_conditions = { account_id: current_account.id  }
    where_conditions[:inbox_id] = accessable_inbox_ids unless should_skip_inbox_filtering?

    Message.search(
      search_query,
      fields: %w[content attachments.transcribed_text content_attributes.email.subject],
      where: where_conditions,
      order: { created_at: :desc },
      page: params[:page] || 1,
      per_page: 15
    )
  end
end
