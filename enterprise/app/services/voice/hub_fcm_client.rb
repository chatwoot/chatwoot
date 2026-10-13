# Sends FCM messages through the Chatwoot Hub relay, for installations without Firebase
# credentials of their own. Answers send_v1 as the FCM client does, with the status code and
# body FCM gave the hub. The installation details sent with each request are read when the
# client is made, so its deliveries make HTTP requests only.
class Voice::HubFcmClient
  def initialize
    @instance_info = ChatwootHub.instance_config
  end

  def send_v1(message)
    response = ChatwootHub.send_push_with_response(message, instance_info: @instance_info)
    JSON.parse(response.body).symbolize_keys.slice(:status_code, :body)
  end
end
