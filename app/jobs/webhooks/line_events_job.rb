class Webhooks::LineEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: '', post_body: '')
    @params = params.with_indifferent_access
    @channel = Channel::Line.find_by(line_channel_id: @params[:line_channel_id])
    return unless @channel

    events = @channel.webhook_parser.parse(body: post_body, signature: signature)
    normalized_payload = Line::WebhookEventAdapter.normalize(events).with_indifferent_access

    [
      Line::IncomingMessageService,
      Line::DeliveryStatusService
    ].each do |service_class|
      perform_service(service_class, normalized_payload)
    end
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    nil
  end

  private

  def perform_service(service_class, normalized_payload)
    service_class.new(
      inbox: @channel.inbox,
      params: normalized_payload
    ).perform
  rescue StandardError => e
    Rails.logger.error("[LINE] #{service_class.name} failed for channel_id=#{@channel.id}: #{e.class} #{e.message}")
    ChatwootExceptionTracker.new(e, account: @channel.account).capture_exception
  end
end
