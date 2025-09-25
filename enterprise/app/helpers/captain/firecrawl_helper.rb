module Captain::FirecrawlHelper
  def generate_firecrawl_token(assistant_id, account_id)
    api_key = InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
    return nil unless api_key

    token_base = "#{api_key[-4..]}#{assistant_id}#{account_id}"
    Digest::SHA256.hexdigest(token_base)
  end
end
