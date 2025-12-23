require 'helper'

class TestImapXoauth2Authenticator < Test::Unit::TestCase
  
  def setup
  end
  
  def test_xoauth2_authenticator_is_enabled
    authenticators = Net::IMAP.__send__('class_variable_get', '@@authenticators')
    assert_not_nil authenticators['XOAUTH2']
    assert_equal authenticators['XOAUTH2'], GmailXoauth::ImapXoauth2Authenticator
  end
  
  def test_authenticate_with_invalid_credentials
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    assert_raise(Net::IMAP::NoResponseError) do
      imap.authenticate('XOAUTH2', 'roger@moore.com', 'a')
    end
  end
  
  def test_authenticate_with_valid_credentials
    return unless VALID_CREDENTIALS
    
    imap = Net::IMAP.new('imap.gmail.com', 993, usessl = true, certs = nil, verify = false)
    imap.authenticate('XOAUTH2', VALID_CREDENTIALS[:email], VALID_CREDENTIALS[:oauth2_token])
    mailboxes = imap.list('', '*')
    assert_instance_of Array, mailboxes
    assert_instance_of Net::IMAP::MailboxList, mailboxes.first
  ensure
    imap.disconnect if imap
  end
end
