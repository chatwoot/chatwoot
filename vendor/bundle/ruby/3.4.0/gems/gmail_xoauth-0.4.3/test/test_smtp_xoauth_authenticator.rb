require 'helper'

class TestSmtpXoauthAuthenticator < Test::Unit::TestCase
  
  def setup
  end
  
  def test_smtp_authenticator_is_enabled
    assert Net::SMTP.new(nil).respond_to?(:auth_xoauth), 'The Net::SMTP class should define the method :auth_xoauth'
  end
  
  def test_authenticate_with_invalid_credentials
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    assert_raise(Net::SMTPAuthenticationError) do
      smtp.start('gmail.com', 'roger@moore.com', {:token => 'a', :token_secret => 'b'}, :xoauth)
    end
  end
  
  def test_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    
    secret = {
      :consumer_key => VALID_CREDENTIALS[:consumer_key],
      :consumer_secret => VALID_CREDENTIALS[:consumer_secret],
      :token => VALID_CREDENTIALS[:token],
      :token_secret => VALID_CREDENTIALS[:token_secret],
    }
    
    assert_nothing_raised do
      smtp.start('gmail.com', VALID_CREDENTIALS[:email], secret, :xoauth)
    end
  ensure
    smtp.finish if smtp && smtp.started?
  end

  def test_2_legged_authenticate_with_invalid_credentials
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    assert_raise(Net::SMTPAuthenticationError) do
      smtp.start('gmail.com', 'roger@moore.com', {:two_legged => true, :consumer_key => 'a', :consumer_secret => 'b'}, :xoauth)
    end
  end
  
  def test_2_legged_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    smtp = Net::SMTP.new('smtp.gmail.com', 587)
    smtp.enable_starttls_auto
    
    secret = {
			:two_legged => true,
      :consumer_key => VALID_CREDENTIALS[:consumer_key],
      :consumer_secret => VALID_CREDENTIALS[:consumer_secret],
    }
    
    assert_nothing_raised do
      smtp.start('gmail.com', VALID_CREDENTIALS[:email], secret, :xoauth)
    end
  ensure
    smtp.finish if smtp && smtp.started?
  end
end
