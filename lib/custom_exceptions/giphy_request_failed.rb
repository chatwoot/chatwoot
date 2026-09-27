class CustomExceptions::GiphyRequestFailed < CustomExceptions::Base
  def message
    I18n.t('errors.giphy.request_failed', status: @data)
  end

  def http_status
    502
  end
end
