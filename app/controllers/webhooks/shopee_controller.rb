class Webhooks::ShopeeController < ActionController::API
  def process_payload
    # Webhooks::ShopeeEventsJob.perform_later()
    head :ok
  end
end
