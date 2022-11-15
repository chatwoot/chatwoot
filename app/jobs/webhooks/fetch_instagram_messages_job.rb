class Inboxes::FetchInstagramMessagesJob < ApplicationJob
  queue_as :low

  def perform
    @channel = Channel::FacebookPage.where.not(instagram_id: nil).last

    return if @channel.nil?

    ::Instagram::MockWebhookService.new.perform
  end
end
