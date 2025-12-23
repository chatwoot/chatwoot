require 'net/smtp'
require 'oauth'

module GmailXoauth
  module SmtpXoauthAuthenticator
    
    def auth_xoauth(user, secret)
      check_auth_args user, secret
      
      request_url  = "https://mail.google.com/mail/b/#{user}/smtp/"

      if secret[:two_legged]
        request_url += "?xoauth_requestor_id=#{CGI.escape(user)}";
				secret = secret.merge({:xoauth_requestor_id => user})
      end

      oauth_string = build_oauth_string(request_url, secret)

      sasl_client_request = build_sasl_client_request(request_url, oauth_string)
      
      res = critical {
        get_response("AUTH XOAUTH #{base64_encode(sasl_client_request)}")
      }
      
      check_auth_response res
      res
    end
    
    include OauthString
    
  end
end

# Not pretty, right ?
Net::SMTP.__send__('include', GmailXoauth::SmtpXoauthAuthenticator)
