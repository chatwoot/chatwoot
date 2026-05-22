class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  retry_on Firecrawl::FirecrawlError, wait: :polynomially_longer, attempts: 3 do |job, error|
    job.send(:on_writer_failure, error)
  end

  discard_on Onboarding::HelpCenterErrors::ArticleBuildFailed do |job, error|
    job.send(:on_writer_failure, error)
  end

  def perform(account_id, portal_id, user_id, generation_id, article_payload)
    user = User.find(user_id)
    payload = article_payload.with_indifferent_access
    article = Onboarding::HelpCenterArticleBuilder.new(
      account: Account.find(account_id),
      portal: Portal.find(portal_id),
      user: user,
      article: payload[:article]
    ).perform

    finalize(user: user, generation_id: generation_id, article: article)
  end

  private

  def on_writer_failure(error)
    user, generation_id = failure_context
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} failed: #{error.class} #{error.message}"
    finalize(user: user, generation_id: generation_id, article: nil)
  end

  def failure_context
    _account_id, _portal_id, user_id, generation_id = arguments
    [User.find_by(id: user_id), generation_id]
  end

  def finalize(user:, generation_id:, article:)
    result = Onboarding::HelpCenterGenerationState.record_article_finished(generation_id)

    if article
      Onboarding::HelpCenterBroadcaster.article_generated(
        user: user, generation_id: generation_id, article: article, articles_finished: result[:finished]
      )
    end
    return unless result[:completed]

    Onboarding::HelpCenterBroadcaster.completed(user: user, generation_id: generation_id, status: 'completed')
  rescue Onboarding::HelpCenterGenerationState::Missing => e
    Rails.logger.warn "[HelpCenterWriterJob] gen=#{generation_id} #{e.message}"
  end
end
