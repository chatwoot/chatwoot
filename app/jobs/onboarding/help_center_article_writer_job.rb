class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on CustomExceptions::HelpCenter::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(account_id, portal_id, user_id, generation_id, article_payload)
    account = Account.find(account_id)
    user = User.find(user_id)
    payload = article_payload.with_indifferent_access
    article = Onboarding::HelpCenterArticleBuilder.new(
      account: account,
      portal: Portal.find(portal_id),
      user: user,
      article: payload[:article],
      allowed_urls: payload[:allowed_urls]
    ).perform

    finalize(account: account, user: user, generation_id: generation_id, article: article)
  end

  private

  def on_writer_failure(error)
    account_id, _portal_id, user_id, generation_id = arguments
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} failed: #{error.class} #{error.message}"
    finalize(account: Account.find(account_id), user: User.find_by(id: user_id), generation_id: generation_id, article: nil)
  end

  def finalize(account:, user:, generation_id:, article:)
    result = Onboarding::HelpCenterGenerationCounter.record_finished!(generation_id)

    if article
      Onboarding::HelpCenterBroadcaster.article_generated(
        user: user, generation_id: generation_id, article: article, articles_finished: result[:finished]
      )
    end
    return unless result[:completed]

    return unless Onboarding::HelpCenterGenerationStatus.mark_completed!(account, generation_id)

    Onboarding::HelpCenterBroadcaster.completed(user: user, generation_id: generation_id, status: 'completed')
  rescue Onboarding::HelpCenterGenerationCounter::Missing => e
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} #{e.message}"
  end
end
