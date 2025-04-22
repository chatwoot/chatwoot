class Integrations::Shopee::Conversation < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 60

  def list
    auth_client.query({
                        direction: :older,
                        type: :all,
                        page_size: MAX_PAGE_SIZE
                      }).get('/api/v2/sellerchat/get_conversation_list')
  end

  def detail(conversation_id)
    auth_client
      .query({ conversation_id: conversation_id })
      .get('/api/v2/sellerchat/get_one_conversation')
  end
end
