class Inboxes::RefreshAccessTokensJob < ApplicationJob
  queue_as :scheduled_jobs

  REMAINING_TIME = 31.minutes

  def perform
    Inbox.where(channel_type: scoped_channels).find_each do |inbox|
      inbox.channel.refresh_access_token! if inbox.channel.expire_in?(REMAINING_TIME)
    end
  end

  private

  def scoped_channels
    [
      Channel::Shopee.model_name.name,
      Channel::Zalo.model_name.name
    ]
  end
end
