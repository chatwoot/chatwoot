class SdkAndroidConfiguration < ApplicationRecord
  belongs_to :sdk_app
  encrypts :service_account

  validates :sdk_app_id, uniqueness: true
  validates :package_name, :project_id, :service_account, presence: true
  validates :package_name, format: { with: /\A[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+\z/ }, length: { maximum: 255 }
  validates :project_id, format: { with: /\A[a-z][a-z0-9-]{4,28}[a-z0-9]\z/ }
  validates :service_account, length: { maximum: 16_384 }
  validate :valid_service_account
  validate :unchanged_destination
  before_destroy :clear_devices

  private

  def clear_devices
    sdk_app.sdk_push_devices.where(platform: 'android').destroy_all
  end

  def unchanged_destination
    return unless persisted? && (package_name_changed? || project_id_changed?) && sdk_app.sdk_push_devices.exists?(platform: 'android')

    errors.add(:base, 'Remove the Android configuration before changing the package or Firebase project while devices are registered')
  end

  def matching_service_account?(credentials)
    return false unless credentials.is_a?(Hash)

    expected = { 'type' => 'service_account', 'project_id' => project_id, 'token_uri' => 'https://oauth2.googleapis.com/token' }
    expected.all? { |key, value| credentials[key] == value } && credentials['client_email'].to_s.end_with?('.iam.gserviceaccount.com')
  end

  def valid_service_account
    return if service_account.blank?

    credentials = JSON.parse(service_account)
    unless matching_service_account?(credentials)
      errors.add(:service_account, 'must be a Firebase service account for this project')
      return
    end
    key = OpenSSL::PKey.read(credentials.fetch('private_key'))
    errors.add(:service_account, 'must contain a private RSA key') unless key.is_a?(OpenSSL::PKey::RSA) && key.private?
  rescue JSON::ParserError, OpenSSL::PKey::PKeyError, KeyError, ArgumentError, TypeError
    errors.add(:service_account, 'must be a valid Firebase service account JSON file')
  end
end
