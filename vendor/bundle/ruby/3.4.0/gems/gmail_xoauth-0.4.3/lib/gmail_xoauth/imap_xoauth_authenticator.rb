require 'net/imap'
require 'oauth'

module GmailXoauth
  class ImapXoauthAuthenticator
    
    def process(data)
      build_sasl_client_request(@request_url, @oauth_string)
    end
    
  private
    
    # +user+ is an email address: roger@gmail.com
    # +password+ is a hash of oauth parameters, see +build_oauth_string+
    def initialize(user, password)
      @request_url = "https://mail.google.com/mail/b/#{user}/imap/";

      if password[:two_legged]
        password = password.merge({:xoauth_requestor_id => user})
        @request_url += "?xoauth_requestor_id=#{CGI.escape(user)}";
      end

      @oauth_string = build_oauth_string(@request_url, password)
    end
    
    include OauthString
    
  end
end

if Net::IMAP.const_defined?('SASL') && Net::IMAP::SASL.respond_to?(:add_authenticator)
  Net::IMAP::SASL.add_authenticator('XOAUTH', GmailXoauth::ImapXoauthAuthenticator)
else
  Net::IMAP.add_authenticator('XOAUTH', GmailXoauth::ImapXoauthAuthenticator)
end
