class Webhooks::WebflowEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    @params = params
    return unless valid_event_payload?

    Digitaltolk::WebflowService.new(params: @params).perform
  end

  private

  def valid_event_payload?
    true
  end
end
