class Webhooks::FacebookDeliveryJob < MutexApplicationJob
  queue_as :default
  retry_on LockAcquisitionError, wait: 1.second, attempts: 8

  def perform(_delivery)
    # byebug
  end
end
