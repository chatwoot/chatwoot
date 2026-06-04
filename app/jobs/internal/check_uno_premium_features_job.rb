class Internal::CheckUnoPremiumFeaturesJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    # Enforce premium configurations
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'premium')
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: '1000000')
    InstallationConfig.find_or_create_by(name: 'CAPTAIN_CLOUD_PLAN_LIMITS').update!(value: '')
  end
end
