class Inboxes::FetchInstagramMessagesJob < ApplicationJob
  queue_as :low

  def perform
    Instagram::MockWebhookService.new.perform
  end
end
