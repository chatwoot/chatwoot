class Webhooks::EvolutionGoJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    EvolutionGo::WebhookService.new(params: params).perform
  end
end
