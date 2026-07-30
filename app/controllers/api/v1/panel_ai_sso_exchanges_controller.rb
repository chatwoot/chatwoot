# frozen_string_literal: true

class Api::V1::PanelAiSsoExchangesController < ApplicationController
  skip_before_action :set_current_user

  # Server-to-server: Panel exchanges email + sso_auth_token for identity.
  def create
    secret = request.headers['X-Panel-SSO-Secret'].to_s
    expected = ENV.fetch('PANEL_SSO_SHARED_SECRET', '').to_s
    if expected.blank? || secret.blank? || !ActiveSupport::SecurityUtils.secure_compare(secret, expected)
      return render json: { error: 'unauthorized' }, status: :unauthorized
    end

    email = params[:email].to_s.strip.downcase
    token = params[:sso_auth_token].to_s
    if email.blank? || token.blank?
      return render json: { error: 'email and sso_auth_token required' }, status: :bad_request
    end

    user = User.find_by('lower(email) = ?', email)
    unless user&.valid_sso_auth_token?(token)
      return render json: { error: 'invalid_token' }, status: :unauthorized
    end

    user.invalidate_sso_auth_token(token)

    admin_account_ids = user.account_users.administrator.pluck(:account_id)
    render json: {
      email: user.email,
      name: user.name,
      chatwoot_user_id: user.id,
      is_super_admin: user.type == 'SuperAdmin',
      admin_account_ids: admin_account_ids
    }
  end
end
