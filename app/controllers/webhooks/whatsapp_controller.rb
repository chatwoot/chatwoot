class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
