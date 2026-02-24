# frozen_string_literal: true

class Aloo::SyncArticleJob < ApplicationJob
  queue_as :low

  def perform(article_id)
    article = Article.find_by(id: article_id)
    return if article.nil? || !article.published?

    assistants = assistants_for_article(article)
    return if assistants.empty?

    assistants.each { |assistant| sync_to_assistant(article, assistant) }
  end

  private

  def assistants_for_article(article)
    article.portal.inboxes.includes(:aloo_assistant).filter_map(&:aloo_assistant).uniq
  end

  def sync_to_assistant(article, assistant)
    document = assistant.documents.find_or_initialize_by(article_id: article.id)
    was_new = document.new_record?

    document.assign_attributes(
      source_type: 'article',
      account_id: assistant.account_id,
      title: article.title,
      text_content: article.to_llm_text
    )
    document.save!

    was_new ? document.process_async! : document.reprocess!
  end
end
