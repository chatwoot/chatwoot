class Channels::Telegram::ReRegisterWebhooksJob < ApplicationJob
  queue_as :low

  def perform
    Channel::Telegram.joins(:inbox).joins(:account)
                     .merge(Account.active)
                     .distinct
                     .find_each(batch_size: 100) do |channel|
      Telegram::WebhookSetupService.new(channel: channel).perform
    end
  end
end
