class Mfa::AuthenticationService
  pattr_initialize [:user!, :otp_code, :backup_code]

  def authenticate
    return false unless user

    return authenticate_with_otp if otp_code.present?
    return authenticate_with_backup_code if backup_code.present?

    false
  end

  private

  def authenticate_with_otp
    user.validate_and_consume_otp!(otp_code)
  end

  def authenticate_with_backup_code
    mfa_service = Mfa::ManagementService.new(user: user)
    mfa_service.validate_backup_code!(backup_code)
  end
end
