# frozen_string_literal: true

# Reception-desk agents authenticate with name + numeric PIN (stored as Devise password).
# Marked via custom_attributes['desk_login'] so only these users use the desk login path.
module DeskLoginable
  extend ActiveSupport::Concern

  DESK_LOGIN_ATTR = 'desk_login'
  PIN_FORMAT = /\A\d{4,6}\z/

  included do
    scope :with_desk_login, -> { where("custom_attributes->>'#{DESK_LOGIN_ATTR}' = ?", 'true') }
  end

  def desk_login?
    ActiveModel::Type::Boolean.new.cast(custom_attributes&.[](DESK_LOGIN_ATTR))
  end

  # Sets a numeric PIN as the Devise password and flags the user for desk login.
  # Skips password-complexity validations so short numeric PINs are allowed.
  def enable_desk_login!(pin:)
    pin = pin.to_s
    raise ArgumentError, 'PIN must be 4-6 digits' unless pin.match?(PIN_FORMAT)

    self.password = pin
    self.password_confirmation = pin
    self.custom_attributes = (custom_attributes || {}).merge(DESK_LOGIN_ATTR => true)
    skip_confirmation! if respond_to?(:skip_confirmation!) && !confirmed?
    self.confirmed_at ||= Time.current
    self.uid = email if uid.blank?
    save!(validate: false)
  end
end
