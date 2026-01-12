class CustomExceptions::Report::InvalidDateRange < CustomExceptions::Base
  def message
    I18n.t('errors.reports.date_range_too_long')
  end

  def http_status
    :unprocessable_entity
  end
end
