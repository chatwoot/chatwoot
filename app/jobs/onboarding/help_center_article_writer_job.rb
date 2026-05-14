class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on CustomExceptions::HelpCenter::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(generation, article_index)
    article = Onboarding::HelpCenterArticleBuilder.new(
      account: generation.account,
      portal: generation.portal,
      user: generation.account.administrators.first,
      article: generation.plan['articles'][article_index],
      allowed_urls: generation.allowed_urls
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
    generation.record_article_finished!

    Onboarding::HelpCenterBroadcaster.article_generated(generation, article) if article
    Onboarding::HelpCenterBroadcaster.completed(generation) if generation.complete_if_finished!
  end
end
