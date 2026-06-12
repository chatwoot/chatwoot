module Enterprise::Api::V1::Accounts::OnboardingsController
  def help_center_generation
    @account = Current.account
    render json: help_center_generation_status
  end

  private

  def help_center_generation_status
    generation_id = help_center_generation_id
    return super if generation_id.blank?

    state = Onboarding::HelpCenterGenerationState.current(generation_id)

    {
      generation_id: generation_id,
      state: state,
      articles_count: articles_count,
      categories_count: categories_count
    }
  end

  def help_center_generation_id
    @account.custom_attributes['help_center_generation_id']
  end

  def articles_count
    onboarding_portal&.articles&.count || 0
  end

  def categories_count
    onboarding_portal&.categories&.count || 0
  end

  def onboarding_portal
    @onboarding_portal ||= @account.portals.first
  end
end
