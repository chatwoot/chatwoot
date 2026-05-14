class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on CustomExceptions::HelpCenter::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(generation, article_index)
    spec = generation.plan['articles'][article_index].merge('allowed_urls' => generation.plan['allowed_urls'])

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

    Onboarding::HelpCenterBroadcaster.article_generated(generation, article) if article
    transition_to_completed(generation)
  end

  def transition_to_completed(generation)
    statuses = HelpCenterGeneration.statuses
    updated = HelpCenterGeneration.where(id: generation.id, status: statuses[:generating])
                                  .where('articles_finished >= ?', generation.planned_total)
                                  .update_all(status: statuses[:completed], finished_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    return unless updated == 1

    Onboarding::HelpCenterBroadcaster.completed(generation.reload)
  end
end
