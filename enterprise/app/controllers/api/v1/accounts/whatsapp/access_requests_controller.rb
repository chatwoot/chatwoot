class Api::V1::Accounts::Whatsapp::AccessRequestsController < Api::V1::Accounts::BaseController
  FEATURE_NAME = 'whatsapp_embedded_signup_inbox_creation'.freeze

  before_action :check_admin_authorization?

  def create
    raise Pundit::NotAuthorizedError unless ChatwootApp.chatwoot_cloud?

    use_case = params.permit(:use_case).require(:use_case).to_s.strip
    raise ActionController::ParameterMissing, :use_case if use_case.blank?

    account = Current.account
    account.with_lock do
      managed_features = Internal::Accounts::InternalAttributesService.new(account).manually_managed_features
      account.enable_features(FEATURE_NAME)
      account.update!(internal_attributes: account.internal_attributes.merge(
        'whatsapp_use_case' => use_case,
        'manually_managed_features' => managed_features | [FEATURE_NAME]
      ))
    end

    render json: { features: account.enabled_features }
  end
end
