class Api::V1::Profile::MfaController < Api::BaseController
  before_action :authenticate_user!
  before_action :check_mfa_not_enabled, only: [:enable, :verify]
  before_action :check_mfa_enabled, only: [:destroy, :backup_codes]

  def show
    render json: {
      enabled: current_user.mfa_enabled?,
      backup_codes_generated: current_user.backup_codes_generated?
    }
  end

  def enable
    current_user.otp_secret = User.generate_otp_secret
    current_user.save!
    qr_code = build_qr_code
    backup_codes = current_user.generate_backup_codes!

    render json: {
      qr_code_url: qr_code.as_png(size: 200).to_data_url,
      secret: current_user.otp_secret,
      backup_codes: backup_codes
    }
  end

  def verify
    if current_user.validate_and_consume_otp!(verify_params[:otp_code])
      current_user.update!(otp_required_for_login: true)
      render json: { message: I18n.t('profile.mfa.enabled'), enabled: true }
    else
      render json: { error: I18n.t('errors.mfa.invalid_code') }, status: :bad_request
    end
  end

  def destroy
    return render_invalid_credentials unless valid_disable_request?

    current_user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_codes: nil
    )

    render json: { message: I18n.t('profile.mfa.disabled'), enabled: false }
  end

  def backup_codes
    if current_user.validate_and_consume_otp!(backup_codes_params[:otp_code])
      codes = current_user.generate_backup_codes!
      render json: { backup_codes: codes }
    else
      render json: { error: I18n.t('errors.mfa.invalid_code') }, status: :bad_request
    end
  end

  private

  def check_mfa_not_enabled
    return unless current_user.mfa_enabled?

    render json: { error: I18n.t('errors.mfa.already_enabled') }, status: :unprocessable_entity
  end

  def check_mfa_enabled
    return if current_user.mfa_enabled?

    render json: { error: I18n.t('errors.mfa.not_enabled') }, status: :unprocessable_entity
  end

  def verify_params
    params.permit(:otp_code)
  end

  def backup_codes_params
    params.permit(:otp_code)
  end

  def destroy_params
    params.permit(:password, :otp_code)
  end

  def valid_disable_request?
    current_user.valid_password?(destroy_params[:password]) &&
      current_user.validate_and_consume_otp!(destroy_params[:otp_code])
  end

  def render_invalid_credentials
    render json: { error: I18n.t('errors.mfa.invalid_credentials', default: 'Invalid credentials or verification code') },
           status: :bad_request
  end

  def build_qr_code
    require 'rqrcode'

    issuer = Rails.application.class.module_parent.name
    label = "#{issuer}:#{current_user.email}"

    RQRCode::QRCode.new(
      current_user.otp_provisioning_uri(label, issuer: issuer)
    )
  end
end
