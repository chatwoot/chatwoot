# Blocks api_access_token authenticated requests for users who must enrol in MFA.
# Wire the checks with `if: :authenticate_by_access_token?` so session traffic is never gated.
module MfaEnforcementGuard
  extend ActiveSupport::Concern

  private

  def check_account_mfa_enforcement
    account = Current.account || @account
    return unless account&.enforce_mfa?

    render_mfa_enrollment_required if mfa_enforcement_applies?(Current.user)
  end

  def check_user_mfa_enforcement
    user = Current.user
    render_mfa_enrollment_required if user.is_a?(User) && user.mfa_enforcement_pending? && mfa_enforcement_applies?(user)
  end

  def mfa_enforcement_applies?(user)
    user.is_a?(User) && !user.mfa_enabled? && user.provider != 'saml'
  end

  def render_mfa_enrollment_required
    render json: {
      error: I18n.t('errors.mfa.enrollment_required'),
      error_code: 'mfa_enrollment_required'
    }, status: :forbidden
  end
end
