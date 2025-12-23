# This class implements an ActiveJob job for performing reverse-geocoding
# asynchronously. Example usage:

# if @location.save && @location.address.blank?
#   ReverseGeocodeJob.perform_later(@location)
# end

# Be sure to configure the queue adapter in config/application.rb:
# config.active_job.queue_adapter = :sidekiq

# You can read the Rails docs for more information on configuring ActiveJob:
# http://edgeguides.rubyonrails.org/active_job_basics.html

class ReverseGeocodeJob < ActiveJob::Base
  queue_as :high

  def perform(location)
    address = address(location)

    if address.present?
      location.update(address: address)
    end
  end

  private

  def address(location)
    Geocoder.address(location.coordinates)
  rescue => exception
    MonitoringService.notify(exception, location: { id: location.id })

    if retryable?(exception)
      raise exception
    end
  end

  def retryable?(exception)
    exception.is_a?(Timeout::Error) || exception.is_a?(SocketError)
  end
end
