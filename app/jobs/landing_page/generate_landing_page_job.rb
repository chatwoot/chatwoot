class LandingPage::GenerateLandingPageJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 2

  def perform(inbox_id)
    inbox = Inbox.find(inbox_id)
    return unless inbox.channel.is_a?(Channel::WebWidget)
    return unless inbox.channel.auto_generate_landing_page

    LandingPage::RequestLandingPageService.new(inbox).perform
  rescue StandardError => e
    Rails.logger.error "[GENERATE_LANDING_PAGE_JOB] Error generating landing page for inbox #{inbox_id}: #{e.message}"
    raise e
  end
end
