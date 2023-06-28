# Recently (around Feb/Mar 2023), Microsoft has made sending
# email through SMTP with Outlook near impossible, at least
# for single tenant applications.
#
# As such, adding a delivery method to use the Microsoft Graph
# API allows for emails to be sent again.
require 'base64'

class MicrosoftGraphDeliveryMethod
  def initialize(config)
    @config = config
  end

  def deliver!(mail)
    # Create a new API connection, and post the mail to the `me/sendMail` endpoint.
    # https://learn.microsoft.com/en-us/graph/api/user-sendmail#example-4-send-a-new-message-using-mime-format

    headers = {
      'Content-Type' => 'text/plain'
    }
    body = Base64.encode64(mail.to_s)

    graph = MicrosoftGraphApi.new(@config[:token])
    graph.post_to_api('me/sendMail', headers, body)
  end
end
