require 'net/imap'

class Imap::AuthenticationError < StandardError; end

module ExceptionList
  REST_CLIENT_EXCEPTIONS = [RestClient::NotFound, RestClient::GatewayTimeout, RestClient::BadRequest,
                            RestClient::MethodNotAllowed, RestClient::Forbidden, RestClient::InternalServerError,
                            RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout,
                            RestClient::TemporaryRedirect, RestClient::SSLCertificateNotVerified, RestClient::PaymentRequired,
                            RestClient::BadGateway, RestClient::Unauthorized, RestClient::PayloadTooLarge,
                            RestClient::MovedPermanently, RestClient::ServiceUnavailable, Errno::ECONNREFUSED, SocketError].freeze
  SMTP_EXCEPTIONS = [
    Net::SMTPSyntaxError
  ].freeze

  IMAP_EXCEPTIONS = [
    Errno::ECONNREFUSED, Net::OpenTimeout,
    Errno::ECONNRESET, Errno::ENETUNREACH, Net::IMAP::ByeResponseError,
    SocketError
  ].freeze

  IMAP_TRANSIENT_EXCEPTIONS = (IMAP_EXCEPTIONS + [
    EOFError, OpenSSL::SSL::SSLError, Net::IMAP::NoResponseError, Net::IMAP::BadResponseError,
    Net::IMAP::InvalidResponseError, Net::IMAP::ResponseParseError,
    Net::IMAP::ResponseReadError, Net::IMAP::ResponseTooLargeError
  ]).freeze
end
