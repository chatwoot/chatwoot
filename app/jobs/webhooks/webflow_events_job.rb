class Webhooks::WebflowEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    Digitaltolk::WebflowService.new(params: params).perform
  end
end
