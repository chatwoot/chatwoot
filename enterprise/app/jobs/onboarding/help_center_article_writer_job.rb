class Onboarding::HelpCenterArticleWriterJob < ApplicationJob
  queue_as :low

  # Catch-all so no exception type can wedge the generation in "generating".
  # Declared FIRST because ActiveJob searches rescue handlers bottom-to-top:
  # this puts StandardError at the bottom of the search order, so the specific
  # retry_on/discard_on handlers declared below match first for their types.
  #
  # Without this, any error that isn't FirecrawlError or ArticleBuildFailed
  # (e.g. ActiveRecord::RecordInvalid, SSL errors) falls through to ActiveJob's
  # default retries, exhausts them, and lands in the dead set without ever
  # calling finalize -> state stays "generating" at total - 1 until the 7-day
  # Redis TTL expires. on_writer_failure logs the error, so code bugs are still
  # visible; it just also progresses the state.
  discard_on StandardError do |job, error|
    job.send(:on_writer_failure, error)
  end

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
