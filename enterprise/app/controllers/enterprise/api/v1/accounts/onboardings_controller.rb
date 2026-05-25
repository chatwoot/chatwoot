module Enterprise::Api::V1::Accounts::OnboardingsController
  def create_onboarding_inboxes
    super
    create_help_center
  end

  def complete_inbox_setup
    # Drop the onboarding-only generation pointer; the OSS method's save! persists both deletions.
    @account.custom_attributes.delete('help_center_generation_id')
    super
  end

  private

  def create_help_center
    return if website.blank?

    Onboarding::HelpCenterCreationService.new(@account, Current.user).perform
  end

  def website
    custom_attributes_params[:website]
  end
end
