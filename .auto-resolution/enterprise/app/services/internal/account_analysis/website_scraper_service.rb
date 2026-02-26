class Internal::AccountAnalysis::WebsiteScraperService
  def initialize(domain)
    @domain = domain
  end

  def perform
    return nil if @domain.blank?

    Rails.logger.info("Scraping website: #{external_link}")

    begin
      response = HTTParty.get(external_link, follow_redirects: true)
      response.to_s
    rescue StandardError => e
      Rails.logger.error("Error scraping website for domain #{@domain}: #{e.message}")
      nil
    end
  end

  private

  def external_link
    sanitize_url(@domain)
  end

  def sanitize_url(domain)
    url = domain
    url = "https://#{domain}" unless domain.start_with?('http://', 'https://')
    Rails.logger.info("Sanitized URL: #{url}")
    url
  end
end
