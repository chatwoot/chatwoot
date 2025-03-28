class Integrations::Shopee::Conversation < Integrations::Shopee::Base
  MAX_PAGE_SIZE = 60

  def list
    auth_client.query({
                        direction: :latest,
                        type: :all,
                        page_size: MAX_PAGE_SIZE
                      }).get('/api/v2/sellerchat/get_conversation_list')
  end
end
