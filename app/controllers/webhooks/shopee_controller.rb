class Webhooks::ShopeeController < ActionController::API
  def process_payload
    Webhooks::ShopeeEventsJob.perform_later(params: params.to_unsafe_hash)
    head :ok
  end
end
