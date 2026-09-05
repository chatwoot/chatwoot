module Enterprise::CsatSurveyResponsePolicy
  def index?
    csat_report_access? || super
  end

  def metrics?
    csat_report_access? || super
  end

  def download?
    csat_report_access? || super
  end

  def update?
    @account_user.administrator? || csat_report_access?
  end

  private

  def csat_report_access?
    @account_user.custom_role_permission?('report_manage', 'report_csat')
  end
end
