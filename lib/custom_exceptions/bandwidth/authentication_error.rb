class CustomExceptions::Bandwidth::AuthenticationError < StandardError
  def initialize
    super(I18n.t('errors.bandwidth.authentication_failed'))
  end
end
