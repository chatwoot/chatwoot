require 'helper'

class TestImapXoauthAuthenticator < Test::Unit::TestCase
  
  def setup
  end
  
  def test_xoauth_authenticator_is_enabled
    authenticators = Net::IMAP.__send__('class_variable_get', '@@authenticators')
    assert_not_nil authenticators['XOAUTH']
    assert_equal authenticators['XOAUTH'], GmailXoauth::ImapXoauthAuthenticator
  end
  
  def test_authenticate_with_invalid_credentials
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    assert_raise(Net::IMAP::NoResponseError) do
      imap.authenticate('XOAUTH', 'roger@moore.com',
        :token => 'a',
        :token_secret => 'b'
      )
    end
  end
  
  def test_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    imap.authenticate('XOAUTH', VALID_CREDENTIALS[:email],
      :consumer_key => VALID_CREDENTIALS[:consumer_key],
      :consumer_secret => VALID_CREDENTIALS[:consumer_secret],
      :token => VALID_CREDENTIALS[:token],
      :token_secret => VALID_CREDENTIALS[:token_secret]
    )
    mailboxes = imap.list('', '*')
    assert_instance_of Array, mailboxes
    assert_instance_of Net::IMAP::MailboxList, mailboxes.first
  ensure
    imap.disconnect if imap
  end

  def test_2_legged_authenticate_with_invalid_credentials
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    assert_raise(Net::IMAP::NoResponseError) do
      imap.authenticate('XOAUTH', 'roger@moore.com',
        :two_legged => true,
        :consumer_key => 'a',
        :consumer_secret => 'b'
      )
    end
  end
  
  def test_2_legged_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    imap.authenticate('XOAUTH', VALID_CREDENTIALS[:email],
      :two_legged => true,
      :consumer_key => VALID_CREDENTIALS[:consumer_key],
      :consumer_secret => VALID_CREDENTIALS[:consumer_secret]
    )
    mailboxes = imap.list('', '*')
    assert_instance_of Array, mailboxes
    assert_instance_of Net::IMAP::MailboxList, mailboxes.first
  ensure
    imap.disconnect if imap
  end

end
