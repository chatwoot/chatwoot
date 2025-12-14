class Mfa::ManagementService
  pattr_initialize [:user!]

  def enable_two_factor!
    user.otp_secret = User.generate_otp_secret
    user.save!
  end

  def disable_two_factor!
    user.otp_secret = nil
    user.otp_required_for_login = false
    user.otp_backup_codes = nil
    user.save!
  end

  def verify_and_activate!
    ActiveRecord::Base.transaction do
      user.update!(otp_required_for_login: true)
      backup_codes_generated? ? nil : generate_backup_codes!
    end
  end

  def two_factor_provisioning_uri
    return nil if user.otp_secret.blank?

    issuer = 'Chatwoot'
    label = user.email
    user.otp_provisioning_uri(label, issuer: issuer)
  end

  def generate_backup_codes!
    codes = Array.new(10) { SecureRandom.hex(4).upcase }
    user.otp_backup_codes = codes
    user.save!
    codes
  end

  def validate_backup_code!(code)
    return false unless valid_backup_code_input?(code)

    codes = user.otp_backup_codes
    found_index = find_matching_code_index(codes, code)

    return false if found_index.nil?

    mark_code_as_used(codes, found_index)
  end

  private

  def valid_backup_code_input?(code)
    user.otp_backup_codes.present? && code.present?
  end

  def find_matching_code_index(codes, code)
    found_index = nil

    # Constant-time comparison to prevent timing attacks
    codes.each_with_index do |stored_code, idx|
      is_match = ActiveSupport::SecurityUtils.secure_compare(stored_code, code)
      is_unused = stored_code != 'XXXXXXXX'
      found_index = idx if is_match && is_unused
    end

    found_index
  end

  def mark_code_as_used(codes, index)
    codes[index] = 'XXXXXXXX'
    user.otp_backup_codes = codes
    user.save!
    true
  end

  public

  def backup_codes_generated?
    user.otp_backup_codes.present?
  end

  def mfa_enabled?
    user.otp_required_for_login?
  end

  def two_factor_setup_pending?
    user.otp_secret.present? && !user.otp_required_for_login?
  end
end
