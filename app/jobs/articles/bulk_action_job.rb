class Articles::BulkActionJob < ApplicationJob
  queue_as :medium

  def perform(portal, user, article_ids, action, value)
    Articles::BulkActionService.new(articles: portal.articles.where(id: article_ids), action: action, value: value, skip_invalid: true).perform

    ActionCableBroadcastJob.perform_later([user.pubsub_token], 'article.bulk_action_completed', { account_id: portal.account_id })
  end
end
