class Integrations::CustomApi::ImportOrdersJob < ApplicationJob
  queue_as :default

  def perform(custom_api)
    # Integrations::CustomApi::ImportOrderService.new(custom_api: custom_api).import_orders
  end
end
