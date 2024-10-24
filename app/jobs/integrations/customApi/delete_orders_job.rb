class Integrations::CustomApi::DeleteOrdersJob < ApplicationJob
  queue_as :default

  def perform(platform_name)
    Order.where(platform: platform_name).destroy_all
  end
end
