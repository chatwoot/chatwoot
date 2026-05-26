class Api::V1::Accounts::OnboardingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  ONBOARDING_STEPS = %w[account_details inbox_setup].freeze

  def update
    @account = Current.account
    complete_onboarding_step

    render 'api/v1/accounts/update', format: :json
  end

  private

  # The client declares which step it is completing; step `foo` runs
  # `complete_foo`, which owns persisting that step's data, advancing the cursor,
  # and any side effects. Dispatch is gated on the known-step list so the client
  # value can never `send` an arbitrary method.
  def complete_onboarding_step
    step = params[:onboarding_step]
    return unless ONBOARDING_STEPS.include?(step)

    send("complete_#{step}")
  end

  def complete_account_details
    @account.assign_attributes(account_params)
    @account.custom_attributes.merge!(custom_attributes_params)
    @account.custom_attributes['onboarding_step'] = 'inbox_setup'
    @account.save!
    create_onboarding_inboxes
  end

  def complete_inbox_setup
    @account.custom_attributes.delete('onboarding_step')
    @account.save!
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
