class Articles::BulkActionService
  pattr_initialize [:articles!, :action!, :value, { skip_invalid: false }]

  def perform
    articles.find_each do |article|
      case action
      when 'update_status' then update_status(article)
      when 'update_category' then article.update!(category_id: value)
      when 'delete' then article.destroy!
      end
    rescue ActiveRecord::RecordInvalid
      raise unless skip_invalid
    end
  end

  private

  def update_status(article)
    return article.update!(status: value) unless unpublished_edits?(article)

    publish_edits(article) if value == 'published'
  end

  def unpublished_edits?(article)
    article.published? && (!article.draft_title.nil? || !article.draft_content.nil?)
  end

  def publish_edits(article)
    article.update!(
      title: article.draft_title || article.title,
      content: article.draft_content || article.content,
      draft_title: nil,
      draft_content: nil
    )
  end
end
