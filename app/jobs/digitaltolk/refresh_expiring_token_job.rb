class Digitaltolk::RefreshExpiringTokenJob < ApplicationJob
  queue_as :low

  def perform
    UserAuth.expiring_soon.find_each(&:schedule_refresh_token)
  end
end
