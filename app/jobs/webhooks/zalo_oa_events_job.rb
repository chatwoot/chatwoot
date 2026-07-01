class Webhooks::ZaloOaEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {})
    @params = params.with_indifferent_access
    return unless valid_event_payload?

    ZaloOa::IncomingMessageService.new(inbox: @channel.inbox, params: @params).perform
  end

  private

  def valid_event_payload?
    oa_id = @params.dig(:oa_id) || @params.dig(:event, :oa_id)
    return false unless oa_id

    @channel = Channel::ZaloOa.find_by(oa_id: oa_id)
    @channel.present?
  end
end
