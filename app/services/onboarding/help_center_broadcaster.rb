module Onboarding::HelpCenterBroadcaster
  ARTICLE_GENERATED = 'help_center.article_generated'.freeze
  GENERATION_COMPLETED = 'help_center.generation_completed'.freeze

  module_function

  def article_generated(generation, article)
    broadcast(generation, ARTICLE_GENERATED) do
      { generation_id: generation.id, article_id: article.id, articles_finished: generation.articles_finished }
    end
  end

  def completed(generation)
    broadcast(generation, GENERATION_COMPLETED) do
      { generation_id: generation.id, status: generation.status, skip_reason: generation.skip_reason }
    end
  end

  def broadcast(generation, event)
    token = generation.account.administrators.first&.pubsub_token
    return if token.blank?

    ActionCableBroadcastJob.perform_later([token], event, yield)
  end
end
