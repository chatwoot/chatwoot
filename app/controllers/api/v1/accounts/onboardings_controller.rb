class Api::V1::Accounts::OnboardingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def update
    @account = Current.account
    finalize = finalizing_account_details?

    @account.assign_attributes(account_params)
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.custom_attributes.delete('onboarding_step') if finalize
    @account.save!

    # TODO: re-enable when the help center generation UI is ready to surface progress
    # Onboarding::HelpCenterCreationService.new(@account, Current.user).perform if finalize && website.present?

    render 'api/v1/accounts/update', format: :json
  end

  private

  def finalizing_account_details?
    @account.custom_attributes['onboarding_step'] == 'account_details'
  end

  def website
    custom_attributes_params[:website]
  end

  def account_params
    params.permit(:name, :locale)
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone, :referral_source, :user_role, :website)
  end
end
