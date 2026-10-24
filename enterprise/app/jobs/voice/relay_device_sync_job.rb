class Voice::RelayDeviceSyncJob < ApplicationJob
  queue_as :low

  retry_on(*ExceptionList::REST_CLIENT_EXCEPTIONS, RestClient::TooManyRequests, wait: :polynomially_longer, attempts: 5) do |job, error|
    platform, token, revision = job.arguments
    Voice::RelayDeviceSync.record_state(platform, token, revision, error.is_a?(RestClient::Unauthorized) ? 'rejected' : 'failed')
  end
  # A phone another installation registered stays with it; the diagnostics show it as such
  discard_on RestClient::Conflict do |job, _error|
    Rails.logger.warn("[VOIP PUSH] #{job.arguments.first} device is registered to another installation on the hub relay")
  end

  def perform(platform, token, revision)
    Voice::RelayDeviceSync.new(platform: platform, token: token, revision: revision).perform
  end
end
