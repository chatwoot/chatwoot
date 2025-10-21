module Enterprise::ReportPolicy
  include Enterprise::Concerns::SubscriptionPolicy

  def view?
    # Check subscription feature first (Professional tier+)
    return false unless has_subscription_feature?('reports')

    # Then check role permissions
    @account_user.custom_role&.permissions&.include?('report_manage') || super
  end
end
