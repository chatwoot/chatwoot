require 'rotp'

module Weave
  module Core
    module Api
      class TwoFactorController < ::Api::BaseController
        # Enforce user authentication only
        before_action :authenticate_user!

        def setup
          secret = ROTP::Base32.random_base32
          current_user.update!(two_factor_secret: secret, two_factor_enabled: false)

          label = "WeaveSmart Chat:#{current_user.email}"
          issuer = 'WeaveSmart'
          totp = ROTP::TOTP.new(secret, issuer: issuer)
          render json: {
            secret: secret,
            otpauth_url: totp.provisioning_uri(label)
          }
        end

        def enable
          code = params.require(:code).to_s
          secret = current_user.two_factor_secret.presence || params[:secret].to_s
          return render json: { error: 'No secret set' }, status: :unprocessable_entity if secret.blank?

          totp = ROTP::TOTP.new(secret, issuer: 'WeaveSmart')
          unless totp.verify(code, drift_behind: 30)
            return render json: { error: 'Invalid code' }, status: :unauthorized
          end

          backup_codes = Array.new(8) { SecureRandom.hex(4) }
          current_user.update!(two_factor_secret: secret, two_factor_enabled: true, two_factor_backup_codes: backup_codes, two_factor_last_verified_at: Time.current)
          render json: { enabled: true, backup_codes: backup_codes }
        end

        def disable
          code = params[:code].to_s
          backup = params[:backup_code].to_s

          if current_user.two_factor_enabled
            verified = false
            if code.present? && current_user.two_factor_secret.present?
              totp = ROTP::TOTP.new(current_user.two_factor_secret, issuer: 'WeaveSmart')
              verified ||= totp.verify(code, drift_behind: 30).present?
            end
            if !verified && backup.present?
              codes = current_user.two_factor_backup_codes || []
              if codes.include?(backup)
                verified = true
                codes -= [backup]
                current_user.update!(two_factor_backup_codes: codes)
              end
            end
            return render json: { error: 'Invalid code' }, status: :unauthorized unless verified
          end

          current_user.update!(two_factor_enabled: false, two_factor_secret: nil)
          render json: { enabled: false }
        end
      end
    end
  end
end

