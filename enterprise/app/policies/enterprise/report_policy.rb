module Enterprise::ReportPolicy
  def view?
    super || @account_user.custom_role&.permissions&.include?('report_manage')
  end
end
