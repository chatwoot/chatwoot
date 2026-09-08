class Api::V1::Accounts::OnboardingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?

  ONBOARDING_STEP_KEY = 'onboarding_step'.freeze
  STEP_ACCOUNT_DETAILS = 'account_details'.freeze
  STEP_INBOX_SETUP = 'inbox_setup'.freeze
  ONBOARDING_STEPS = [STEP_ACCOUNT_DETAILS, STEP_INBOX_SETUP].freeze

  def update
    return render json: { error: 'Invalid onboarding step' }, status: :unprocessable_entity unless ONBOARDING_STEPS.include?(params[:onboarding_step])

    @account = Current.account
    # The client declares the step it is completing; `account_details` runs
    # `complete_account_details`, and so on. The known-step guard above keeps the
    # client value from `send`-ing an arbitrary method.
    send("complete_#{params[:onboarding_step]}")

    render 'api/v1/accounts/update', format: :json
  end

  def help_center_generation
    render json: help_center_generation_status
  end

  private

  def complete_account_details
    # Only act while the cursor still points here, so a stale replay after
    # onboarding finished can't re-enter it.
    return unless current_step == STEP_ACCOUNT_DETAILS

    @account.assign_attributes(account_params)
    @account.custom_attributes.merge!(custom_attributes_params)

    # inbox_setup is a cloud-only step (DEPLOYMENT_ENV config, not a hardcoded
    # environment check); self-hosted finishes onboarding here.
    if ChatwootApp.chatwoot_cloud?
      move_to_step(STEP_INBOX_SETUP)
      create_onboarding_inboxes
    else
      finish_onboarding
    end
  end

  def complete_inbox_setup
    # Only finalize while the cursor still points here, so a stale or out-of-order
    # request can't end onboarding early. Replays are no-ops.
    return unless current_step == STEP_INBOX_SETUP

    finish_onboarding
  end

  def current_step
    @account.custom_attributes[ONBOARDING_STEP_KEY]
  end

  def move_to_step(step)
    @account.custom_attributes[ONBOARDING_STEP_KEY] = step
    @account.save!
  end

  def finish_onboarding
    @account.custom_attributes.delete(ONBOARDING_STEP_KEY)
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
