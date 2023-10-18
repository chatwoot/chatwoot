# frozen_string_literal: true

class Integrations::Facebook::DeliveryStatus
  pattr_initialize [:params!]

  def perform
    return if facebook_channel.blank?

    process_delivery_status if params.delivery_watermark
    process_read_status if params.read_watermark
  end

  private

  def process_delivery_status
    timestamp = Time.zone.at(params.delivery_watermark.to_i).to_datetime
    # Find all the sent messages before the watermark, and mark them as delivered
    @facebook_channel.inbox.messages.where(status: 'sent').where('messages.created_at <= ?', timestamp).find_each do |message|
      message.update!(status: 'delivered')
    end
  end

  def process_read_status
    timestamp = Time.zone.at(params.read_watermark.to_i).to_datetime
    # Find all the delivered messages before the watermark, and mark them as read
    @facebook_channel.inbox.messages.inbox.where(status: 'delivered').where('messages.created_at <= ?', timestamp).find_each do |message|
      message.update!(status: 'read')
    end
  end

  def facebook_channel
    @facebook_channel ||= Channel::FacebookPage.find_by(page_id: params.recipient_id)
  end
end
