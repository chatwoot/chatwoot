module Aiagent::FirecrawlHelper
  def generate_firecrawl_token(topic_id, account_id)
    api_key = InstallationConfig.find_by(name: 'AIAGENT_FIRECRAWL_API_KEY')&.value
    return nil unless api_key

    token_base = "#{api_key[-4..]}#{topic_id}#{account_id}"
    Digest::SHA256.hexdigest(token_base)
  end
end
