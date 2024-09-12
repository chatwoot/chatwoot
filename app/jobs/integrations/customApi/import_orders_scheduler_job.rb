class Integrations::CustomApi::ImportOrdersSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    CustomApi.order(Arel.sql('orders_last_update IS NULL DESC, orders_last_update ASC'))
             .where('orders_last_update <= ? OR orders_last_update IS NULL', 1.hour.ago)
             .limit(Limits::BULK_EXTERNAL_HTTP_CALLS_LIMIT)
             .each do |custom_api|
      Integrations::CustomApi::ImportOrdersJob.perform_later(custom_api)
    end
  end
end
