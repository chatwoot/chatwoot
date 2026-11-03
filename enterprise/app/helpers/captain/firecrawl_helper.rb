module Captain::FirecrawlHelper
  def generate_firecrawl_token(assistant_id, account_id)
    return if InstallationConfig.find_by(name: 'CAPTAIN_FIRECRAWL_API_KEY')&.value.blank?

    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "firecrawl:#{assistant_id}:#{account_id}")
  end
end
