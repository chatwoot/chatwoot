module Enterprise::Api::V1::Accounts::Conversations::SuggestionsController
  def self.prepended(base)
    base.rescue_from CustomExceptions::JevQuotaError do |error|
      response.set_header('Retry-After', error.retry_after.to_s)
      render json: { error: error.code, retry_after: error.retry_after }, status: :too_many_requests
    end
  end
end
