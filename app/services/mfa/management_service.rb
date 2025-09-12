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
    user.update!(otp_required_for_login: true)
  end

  def provisioning_uri
    return nil if user.otp_secret.blank?

    issuer = 'Chatwoot'
    label = user.email
    user.otp_provisioning_uri(label, issuer: issuer)
  end
  alias two_factor_provisioning_uri provisioning_uri

  def generate_backup_codes!
    codes = Array.new(10) { format('%06d', SecureRandom.random_number(1_000_000)) }
    user.otp_backup_codes = codes
    user.save!
    codes
  end

  def validate_backup_code!(code)
    return false if user.otp_backup_codes.blank? || code.blank?

    codes = user.otp_backup_codes || []
    index = codes.index(code)

    # Code not found or already used
    return false if index.nil? || code == 'XXXXXX'

    # Mark as used and save
    codes[index] = 'XXXXXX'
    user.otp_backup_codes = codes
    user.save!
    true
  end

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
