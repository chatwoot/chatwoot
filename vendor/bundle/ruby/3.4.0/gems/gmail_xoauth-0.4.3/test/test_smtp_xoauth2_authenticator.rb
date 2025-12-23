require 'helper'

class TestSmtpXoauthAuthenticator < Test::Unit::TestCase
  
  def setup
  end
  
  def test_smtp_authenticator_is_enabled
    assert Net::SMTP.new(nil).respond_to?(:auth_xoauth2), 'The Net::SMTP class should define the method :auth_xoauth2'
  end
  
  def test_authenticate_with_invalid_credentials
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    assert_raise(Net::SMTPAuthenticationError) do
      smtp.start('gmail.com', 'roger@moore.com', 'a', :xoauth2)
    end
  end
  
  def test_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    
    assert_nothing_raised do
      smtp.start('gmail.com', VALID_CREDENTIALS[:email], VALID_CREDENTIALS[:oauth2_token], :xoauth2)
    end
  ensure
    smtp.finish if smtp && smtp.started?
  end

  # Test the handling of 3xx response to an "AUTH XOAUTH2" request... client
  # should send a "\r\n" to get the actual error that occurred.
  #
  # See note about SMTP protocol exchange in https://developers.google.com/
  # gmail/xoauth2_protocol
  #
  def test_authenticate_with_continuation
    smtp = Net::SMTP.new('smtp.gmail.com', 587)

    # Stub return from initial "AUTH XOAUTH2" request as well as the empty line sent to get final error
    smtp.stubs(:send_xoauth2).returns(Net::SMTP::Response.parse("334 eyJzdGF0dXMiOiI0MDAiLCJzY2hlbWVzIjoiQmVhcmVyIiwic2NvcGUiOiJodHRwczovL21haWwuZ29vZ2xlLmNvbS8ifQ=="))
    smtp.stubs(:get_final_status).returns(Net::SMTP::Response.parse("454 4.7.0 Too many login attempts, please try again later. j63sm3521185itj.19 - gsmtp"))

    smtp.enable_starttls_auto

    # Validate an error is still raised
    ex = assert_raise(Net::SMTPAuthenticationError) do
      smtp.start('gmail.com', 'roger@moore.com', 'a', :xoauth2)
    end

    # ...and that the 334 is not passed back to the caller.
    assert_equal("454 4.7.0 Too many login attempts, please try again later. j63sm3521185itj.19 - gsmtp", ex.message)
  ensure
    smtp.finish if smtp && smtp.started?
  end
end
