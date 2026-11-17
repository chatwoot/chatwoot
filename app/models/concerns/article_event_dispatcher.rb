module ArticleEventDispatcher
  extend ActiveSupport::Concern
  include Events::Types

  included do
    after_create_commit :dispatch_create_event
    after_update_commit :dispatch_update_event
    after_destroy_commit :dispatch_destroy_event
  end

  def webhook_data
    {
      account: account.webhook_data,
      author: author.try(:webhook_data),
      category: category.try(:webhook_data),
      content: content,
      created_at: created_at,
      description: description,
      id: id,
      locale: locale,
      meta: meta,
      portal: portal.webhook_data,
      position: position,
      slug: slug,
      status: status,
      title: title,
      updated_at: updated_at,
      views: views
    }
  end

  private

  def dispatch_create_event
    Rails.configuration.dispatcher.dispatch(ARTICLE_CREATED, Time.zone.now, article: self)
  end

  def dispatch_update_event
    Rails.configuration.dispatcher.dispatch(ARTICLE_UPDATED, Time.zone.now, article: self, changed_attributes: previous_changes)
  end

  def dispatch_destroy_event
    return if account.nil? || portal.nil?

    Rails.configuration.dispatcher.dispatch(ARTICLE_DELETED, Time.zone.now, article_data: webhook_data)
  end
end
