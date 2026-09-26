class SdkApp < ApplicationRecord
  belongs_to :account
  belongs_to :inbox
  has_many :sdk_push_devices, dependent: :destroy

  has_one :ios_configuration, class_name: 'SdkIosConfiguration', dependent: :destroy
  accepts_nested_attributes_for :ios_configuration, allow_destroy: true

  has_one :android_configuration, class_name: 'SdkAndroidConfiguration', dependent: :destroy
  accepts_nested_attributes_for :android_configuration, allow_destroy: true

  validates :name, presence: true, length: { maximum: 100 }
  before_validation :assign_app_id, on: :create
  validates :app_id, presence: true, uniqueness: true
  validate :matching_account
  before_update :clear_devices, if: :inbox_id_changed?
  validate :supported_inbox

  private

  def assign_app_id
    self.app_id ||= SecureRandom.uuid
  end

  def matching_account
    errors.add(:inbox, 'must belong to this account') if inbox.account_id != account_id
  end

  def clear_devices
    sdk_push_devices.destroy_all
  end

  def supported_inbox
    errors.add(:inbox, 'must be a Website inbox') unless inbox.web_widget?
  end
end
