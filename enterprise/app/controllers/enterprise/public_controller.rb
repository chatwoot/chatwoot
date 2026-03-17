module Enterprise::PublicController
  private

  def check_portal_plan_access
    current_portal = current_portal_for_public_access
    return if current_portal.blank? || current_portal.account.feature_enabled?('help_center')

    render 'public/api/v1/portals/not_active', status: :payment_required
  end
end
