class Internal::AccountAnalysis::ThreatAnalyserService
  def initialize(account)
    @account = account
    @user = account.users.order(id: :asc).first
    @domain = extract_domain_from_email(@user&.email)
  end

  def perform
    if @domain.blank?
      Rails.logger.info("Skipping threat analysis for account #{@account.id}: No domain found")
      return
    end

    website_content = Internal::AccountAnalysis::WebsiteScraperService.new(@domain).perform
    if website_content.blank?
      Rails.logger.info("Skipping threat analysis for account #{@account.id}: No website content found")
      Internal::AccountAnalysis::AccountUpdaterService.new(@account).update_with_analysis(nil, 'Scraping error: No content found')
      return
    end

    content = <<~MESSAGE
      Domain: #{@domain}
      Content: #{website_content}
    MESSAGE
    threat_analysis = Internal::AccountAnalysis::ContentEvaluatorService.new.evaluate(content)
    Rails.logger.info("Completed threat analysis: level=#{threat_analysis['threat_level']} for account-id: #{@account.id}")

    Internal::AccountAnalysis::AccountUpdaterService.new(@account).update_with_analysis(threat_analysis)

    threat_analysis
  end

  private

  def extract_domain_from_email(email)
    return nil if email.blank?

    email.split('@').last
  rescue StandardError => e
    Rails.logger.error("Error extracting domain from email #{email}: #{e.message}")
    nil
  end
end
