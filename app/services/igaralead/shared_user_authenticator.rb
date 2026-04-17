# frozen_string_literal: true

# Authenticates email/password against the shared igaralead database.
#
# Hub stores password hashes using Django's BCryptSHA256PasswordHasher:
#   bcrypt_sha256$<bcrypt-hash>
# where the password is first SHA-256 hashed, then bcrypt-ed.
class Igaralead::SharedUserAuthenticator
  class << self
    def authenticate(email, password)
      new(email, password).authenticate
    end
  end

  def initialize(email, password)
    @email = email.to_s.strip.downcase
    @password = password.to_s
  end

  def authenticate
    return nil if @email.blank? || @password.blank?

    shared_user = Igaralead::SharedUser.find_by(email: @email, active: true)
    return nil unless shared_user
    return nil unless verify_password(shared_user.password_hash)

    shared_user
  rescue ActiveRecord::StatementInvalid
    # Shared DB not properly configured (e.g. dev fallback uses primary DB
    # which lacks Hub-specific columns). Return nil so the caller falls back
    # to standard Nexus/Chatwoot authentication.
    nil
  end

  private

  def verify_password(stored_hash)
    return false if stored_hash.blank?

    if stored_hash.start_with?('bcrypt_sha256$')
      # Django BCryptSHA256PasswordHasher format:
      # bcrypt_sha256$$2b$12$<salt><hash>
      bcrypt_part = stored_hash.delete_prefix('bcrypt_sha256$')
      sha256_pass = Digest::SHA256.hexdigest(@password)
      BCrypt::Password.new(bcrypt_part) == sha256_pass
    elsif stored_hash.start_with?('$2')
      # Plain bcrypt
      BCrypt::Password.new(stored_hash) == @password
    else
      false
    end
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
