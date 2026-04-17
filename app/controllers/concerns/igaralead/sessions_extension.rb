module Igaralead
  module SessionsExtension
    extend ActiveSupport::Concern

    private

    def find_user_for_authentication
      email = params[:email]&.strip&.downcase
      password = params[:password]
      return nil if email.blank? || password.blank?

      # Validate password against shared DB (Hub's users table)
      shared_user = Igaralead::SharedUser.find_by(email: email)
      return nil unless shared_user
      return nil unless shared_user.respond_to?(:active?) ? shared_user.active? : shared_user.active

      return nil unless valid_shared_password?(password, shared_user.password_hash)

      # Find or create local Nexus user
      user = User.find_by(hub_id: shared_user.id.to_s) || User.from_email(email)
      unless user
        user = create_local_user(shared_user)
      end

      return nil unless user&.active_for_authentication?

      # Ensure hub_id is synced
      if user.hub_id.blank?
        user.update(hub_id: shared_user.id.to_s, hub_synced_at: Time.current)
      end

      user
    end

    def valid_shared_password?(password, stored_hash)
      return false if stored_hash.blank? || stored_hash == '!'

      if stored_hash.start_with?('bcrypt_sha256$')
        # Django BCryptSHA256PasswordHasher: SHA256 the password, then bcrypt
        bcrypt_hash = stored_hash.sub(/\Abcrypt_sha256\$\$?/, '')
        sha256_password = Digest::SHA256.hexdigest(password)
        BCrypt::Password.new(bcrypt_hash) == sha256_password
      elsif stored_hash.start_with?('bcrypt$')
        # Django BCryptPasswordHasher: plain bcrypt
        bcrypt_hash = stored_hash.sub(/\Abcrypt\$\$?/, '')
        BCrypt::Password.new(bcrypt_hash) == password
      else
        false
      end
    rescue BCrypt::Errors::InvalidHash => e
      Rails.logger.warn("[Igaralead] BCrypt validation error: #{e.message}")
      false
    end

    def create_local_user(shared_user)
      user = User.new(
        email: shared_user.email,
        name: shared_user.name,
        hub_id: shared_user.id.to_s,
        hub_synced_at: Time.current,
        password: SecureRandom.alphanumeric(24),
        confirmed_at: Time.current
      )
      user.skip_confirmation!
      user.save!
      user
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[Igaralead] Failed to create user for #{shared_user.email}: #{e.message}")
      nil
    end
  end
end
