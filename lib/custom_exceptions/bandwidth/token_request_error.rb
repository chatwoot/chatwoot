class CustomExceptions::Bandwidth::TokenRequestError < StandardError
  def initialize
    super(I18n.t('errors.bandwidth.token_request_failed'))
  end
end
