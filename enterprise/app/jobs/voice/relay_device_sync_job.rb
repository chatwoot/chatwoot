class Voice::RelayDeviceSyncJob < ApplicationJob
  queue_as :low

  retry_on(*ExceptionList::REST_CLIENT_EXCEPTIONS, RestClient::TooManyRequests, wait: :polynomially_longer, attempts: 5)
  # A phone another installation registered stays with it; Voice::RingReadiness shows it unreachable
  discard_on RestClient::Conflict do |job, _error|
    Rails.logger.warn("[VOIP PUSH] #{job.arguments.first} device is registered to another installation on the hub relay")
  end

  def perform(platform, token)
    Voice::RelayDeviceSync.new(platform: platform, token: token).perform
  end
end
