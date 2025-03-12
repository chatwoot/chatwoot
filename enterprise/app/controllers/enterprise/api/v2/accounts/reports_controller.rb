module Enterprise::Api::V2::Accounts::ReportsController
  def check_authorization
    return if Current.account_user.custom_role&.permissions&.include?('report_manage')

    super
  end
end
