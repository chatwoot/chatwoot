class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on CustomExceptions::HelpCenter::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(generation, article_index)
    spec = generation.plan['articles'][article_index].with_indifferent_access

    article = Onboarding::HelpCenterArticleBuilder.new(
      account: generation.account,
      portal: generation.portal,
      user: generation.account.administrators.first,
      article: spec
    ).perform

    finalize(generation, article: article)
  end

  private

  def on_writer_failure(error)
    generation = arguments.first
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation.id} failed: #{error.class} #{error.message}"
    finalize(generation, article: nil)
  end

  def finalize(generation, article:)
    HelpCenterGeneration.update_counters(generation.id, articles_finished: 1) # rubocop:disable Rails/SkipsModelValidations
    generation.reload

    broadcast_article_generated(generation, article) if article

    return unless generation.all_finished? && !generation.terminal?

    generation.update!(status: :completed, finished_at: Time.current)
    broadcast_completed(generation)
  end

  def broadcast_article_generated(generation, article)
    token = generation.account.administrators.first&.pubsub_token
    return if token.blank?

    ActionCableBroadcastJob.perform_later(
      [token],
      'help_center.article_generated',
      { generation_id: generation.id, article_id: article.id, articles_finished: generation.articles_finished }
    )
  end

  def broadcast_completed(generation)
    token = generation.account.administrators.first&.pubsub_token
    return if token.blank?

    ActionCableBroadcastJob.perform_later(
      [token],
      'help_center.generation_completed',
      { generation_id: generation.id, status: generation.status, skip_reason: generation.skip_reason }
    )
  end
end
