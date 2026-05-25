class Api::V1::Accounts::OnboardingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  def update
    @account = Current.account
    # The client tells us which step it is completing; we trust it. Advancing is
    # a pure function of the declared step, so replays stay idempotent:
    # account_details always lands on inbox_setup, inbox_setup always clears.
    step = params[:onboarding_step]

    @account.assign_attributes(account_params)
    @account.custom_attributes.merge!(custom_attributes_params)
    advance_onboarding_step(step)
    @account.save!

    create_onboarding_inboxes if step == 'account_details'

    render 'api/v1/accounts/update', format: :json
  end

  private

  def advance_onboarding_step(step)
    case step
    when 'account_details'
      @account.custom_attributes['onboarding_step'] = 'inbox_setup'
    when 'inbox_setup'
      @account.custom_attributes.delete('onboarding_step')
    end
  end

  def create_onboarding_inboxes
    Onboarding::WebWidgetCreationService.new(@account, Current.user).perform
  end

  def account_params
    params.permit(:name, :locale)
  end

  def custom_attributes_params
    params.permit(:industry, :company_size, :timezone, :referral_source, :user_role, :website)
  end
end

Api::V1::Accounts::OnboardingsController.prepend_mod_with('Api::V1::Accounts::OnboardingsController')
