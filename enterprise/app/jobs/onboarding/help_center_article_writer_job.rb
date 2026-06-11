class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on Onboarding::HelpCenterErrors::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(account_id, portal_id, user_id, generation_id, article)
    Onboarding::HelpCenterArticleBuilder.new(
      account: Account.find(account_id),
      portal: Portal.find(portal_id),
      user: User.find(user_id),
      article: article
    ).perform

    finalize(generation_id: generation_id)
  end

  private

  def on_writer_failure(error)
    generation_id = arguments[3]
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} failed: #{error.class} #{error.message}"
    finalize(generation_id: generation_id)
  end

  def finalize(generation_id:)
    Onboarding::HelpCenterGenerationState.record_article_finished(generation_id)
  rescue Onboarding::HelpCenterGenerationState::Missing => e
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} #{e.message}"
  end
end
