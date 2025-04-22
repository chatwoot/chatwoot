class Integrations::Shopee::Message < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 60

  def list(conversation_id)
    auth_client.query({
                        conversation_id: conversation_id,
                        page_size: MAX_PAGE_SIZE
                      }).get('/api/v2/sellerchat/get_message')
  end

  def create(user_id, message)
    auth_client.body({
                       to_id: user_id,
                       message_type: :text,
                       content: {
                         text: message
                       }
                     }).post('/api/v2/sellerchat/send_message')
  end
end
