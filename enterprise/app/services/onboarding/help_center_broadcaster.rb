module Onboarding::HelpCenterBroadcaster
  ARTICLE_GENERATED = 'help_center.article_generated'.freeze
  GENERATION_COMPLETED = 'help_center.generation_completed'.freeze

  module_function

  def article_generated(account_id:, user:, generation_id:, article:, articles_finished:)
    broadcast(user, ARTICLE_GENERATED, {
                account_id: account_id,
                generation_id: generation_id,
                article_id: article.id,
                articles_finished: articles_finished
              })
  end

  def completed(account_id:, user:, generation_id:, status:, skip_reason: nil)
    broadcast(user, GENERATION_COMPLETED, {
                account_id: account_id,
                generation_id: generation_id,
                status: status,
                skip_reason: skip_reason
              })
  end

  def broadcast(user, event, payload)
    token = user&.pubsub_token
    return if token.blank?

    ActionCableBroadcastJob.perform_later([token], event, payload)
  end
end
