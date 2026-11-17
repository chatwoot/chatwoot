class Articles::BulkActionJob < ApplicationJob
  queue_as :medium

  def perform(portal, user, filters, action, value)
    Articles::BulkActionService.new(articles: portal.articles.search(filters), action: action, value: value, skip_invalid: true).perform

    ActionCableBroadcastJob.perform_later([user.pubsub_token], 'article.bulk_action_completed', { account_id: portal.account_id })
  end
end
