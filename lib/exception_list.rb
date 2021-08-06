module ExceptionList
  REST_CLIENT_EXCEPTIONS = [RestClient::NotFound, RestClient::GatewayTimeout, RestClient::BadRequest,
                            RestClient::MethodNotAllowed, RestClient::Forbidden, RestClient::InternalServerError, RestClient::PayloadTooLarge].freeze
  SMTP_EXCEPTIONS = [
    Net::SMTPSyntaxError
  ].freeze
end
