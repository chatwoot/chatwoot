class Instagram::ReadStatusService < Instagram::WebhooksBaseService
  attr_reader :messaging

  def initialize(messaging)
    super()
    @messaging = messaging
  end

  def perform
    return if instagram_channel.blank?

    process_statuses if message.present?
  end

  def process_statuses
    @message.status = 'read'
    @message.save!
  end

  def instagram_id
    @messaging[:recipient][:id]
  end

  def instagram_channel
    @instagram_channel = Channel::FacebookPage.find_by(instagram_id: instagram_id)
  end

  def message
    return unless @messaging[:read][:mid]

    @message ||= @instagram_channel.inbox.messages.find_by(source_id: @messaging[:read][:mid])
  end
end
