module Enterprise::Api::V1::Accounts::OnboardingsController
  def create_onboarding_inboxes
    super
    create_help_center
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
