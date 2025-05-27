class Webhooks::ShopeeController < ActionController::API
  def process_payload
    Webhooks::ShopeeEventsJob.new.perform(params: params.to_unsafe_hash)
    head :ok
  end
end
