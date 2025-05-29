module Enterprise::CsatSurveyResponsePolicy
  def index?
    @account_user.custom_role&.permissions&.include?('report_manage') || super
  end

  def metrics?
    @account_user.custom_role&.permissions&.include?('report_manage') || super
  end

  def download?
    @account_user.custom_role&.permissions&.include?('report_manage') || super
  end
end
