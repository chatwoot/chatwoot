require 'net/smtp'
require 'base64'

module GmailXoauth
  module SmtpXoauth2Authenticator

    def send_xoauth2(auth_token)
      critical {
        get_response("AUTH XOAUTH2 #{auth_token}")
      }
    end
    private :send_xoauth2

    def get_final_status
      critical {
        get_response("")
      }
    end
    private :get_final_status

    def auth_xoauth2(user, oauth2_token)
      check_auth_args user, oauth2_token

      auth_string = build_oauth2_string(user, oauth2_token)
      res = send_xoauth2(base64_encode(auth_string))

      # See note about SMTP protocol exchange in https://developers.google.com/gmail/xoauth2_protocol
      if res.continue?
        res = get_final_status
      end
      
      check_auth_response res
      res
    end
    
    include OauthString
    
  end
end

# Not pretty, right ?
Net::SMTP.__send__('include', GmailXoauth::SmtpXoauth2Authenticator)
