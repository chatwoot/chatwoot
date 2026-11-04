module Captain::FirecrawlHelper
  def generate_firecrawl_token(assistant_id, account_id)
    api_key = InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value
    return if api_key.blank?

    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "firecrawl:#{api_key}:#{assistant_id}:#{account_id}")
  end
end
