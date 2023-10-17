# frozen_string_literal: true

class Integrations::Facebook::DeliveryStatus
  pattr_initialize [:params!]

  def perform
    return unless facebook_channel

    process_delivery_status if params.delivery_watermark
    process_read_status if params.read_watermark
  end

  private

  def process_delivery_status
    # Find all the sent messages before the watermark, and mark them as delivered
    @facebook_channel.messages.where(status: 'sent').where('created_at <= ?', params.delivery_watermark).find_each do |message|
      message.update!(status: 'delivered')
    end
  end

  def process_read_status
    # Find all the delivered messages before the watermark, and mark them as read
    @facebook_channel.messages.where(status: 'delivered').where('created_at <= ?', params.read_watermark).find_each do |message|
      message.update!(status: 'read')
    end
  end

  def facebook_channel
    @facebook_channel ||= Channel::FacebookPage.find_by(page_id: params.recipient_id)
  end
end
