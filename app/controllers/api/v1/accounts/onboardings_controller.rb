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

  def help_center_generation
    render json: help_center_generation_status
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

  def help_center_generation_status
    {
      generation_id: nil,
      state: nil,
      articles_count: 0,
      categories_count: 0
    }
  end
end

Api::V1::Accounts::OnboardingsController.prepend_mod_with('Api::V1::Accounts::OnboardingsController')
