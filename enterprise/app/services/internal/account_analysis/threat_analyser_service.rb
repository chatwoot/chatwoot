class Internal::AccountAnalysis::ThreatAnalyserService < Llm::BaseOpenAiService
  def initialize(account)
    @account = account
    @user = account.users.order(id: :asc).first
    @domain = extract_domain_from_email(@user&.email)
    super()
  end

  def perform
    if @domain.blank?
      Rails.logger.info("Skipping threat analysis for account #{@account.id}: No domain found")
      return
    end

    website_content = scrape_website
    if website_content.blank?
      Rails.logger.info("Skipping threat analysis for account #{@account.id}: No website content found")
      return
    end

    threat_analysis = analyze_threats(website_content)
    Rails.logger.info("Completed threat analysis: level=#{threat_analysis['threat_level']} for account-id: #{@account.id}")

    save_analysis_results(threat_analysis)
    flag_account_if_needed(threat_analysis)

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

  def scrape_website
    external_link = sanitize_url(@domain)
    Rails.logger.info("Scraping website: #{external_link}")

    doc = Nokogiri::HTML(HTTParty.get(external_link).body)
    doc.text.strip.gsub(/\s+/, ' ')[0..10_000]
  rescue StandardError => e
    Rails.logger.error("Error scraping website for domain #{@domain}: #{e.message}")
    @account.internal_attributes['last_threat_scan_error'] = "Scraping error: #{e.message}"
    @account.save
    nil
  end

  def analyze_threats(content)
    response = send_to_llm(content)
    analysis = handle_response(response)
    log_analysis_results(analysis)
    analysis
  rescue StandardError => e
    handle_analysis_error(e)
  end

  def handle_response(response)
    return {} if response.nil?

    begin
      # Parse the JSON response
      parsed = JSON.parse(response.dig('choices', 0, 'message', 'content'))

      # Ensure the response has the expected structure
      {
        'threat_level' => parsed['threat_level'] || 'unknown',
        'threat_summary' => parsed['threat_summary'] || 'No threat summary provided',
        'detected_threats' => parsed['detected_threats'] || [],
        'illegal_activities_detected' => parsed['illegal_activities_detected'] || false,
        'recommendation' => parsed['recommendation'] || 'review'
      }
    rescue JSON::ParserError => e
      Rails.logger.error("Error parsing LLM response: #{e.message}")
      {
        'threat_level' => 'unknown',
        'threat_summary' => 'Failed to parse threat analysis',
        'detected_threats' => ['parsing_failure'],
        'illegal_activities_detected' => false,
        'recommendation' => 'review'
      }
    end
  end

  def send_to_llm(content)
    @client.chat(
      parameters: {
        model: @model,
        messages: llm_messages(content),
        response_format: { type: 'json_object' }
      }
    )
  end

  def log_analysis_results(analysis)
    Rails.logger.info("LLM analysis - Threat level: #{analysis['threat_level']}, Illegal activities: #{analysis['illegal_activities_detected']}")
  end

  def handle_analysis_error(error)
    Rails.logger.error("Error analyzing threats: #{error.message}")
    @account.internal_attributes['last_threat_scan_error'] = "Analysis error: #{error.message}"
    @account.save
    {
      'threat_level' => 'unknown',
      'threat_summary' => 'Failed to complete threat analysis',
      'detected_threats' => ['analysis_failure'],
      'illegal_activities_detected' => false,
      'recommendation' => 'review'
    }
  end

  def save_analysis_results(analysis)
    @account.internal_attributes['last_threat_scan_at'] = Time.current
    @account.internal_attributes['last_threat_scan_level'] = analysis['threat_level']
    @account.internal_attributes['last_threat_scan_summary'] = analysis['threat_summary']
    @account.internal_attributes['last_threat_scan_recommendation'] = analysis['recommendation']
    @account.internal_attributes['last_threat_scan_error'] = nil
    @account.save
  end

  def flag_account_if_needed(analysis)
    if %w[high medium].include?(analysis['threat_level']) ||
       analysis['illegal_activities_detected'] == true ||
       analysis['recommendation'] == 'block'

      Rails.logger.info("Flagging account #{@account.id} due to threat level: #{analysis['threat_level']}")

      @account.internal_attributes['security_flagged'] = true
      @account.internal_attributes['security_flag_reason'] = "Threat detected: #{analysis['threat_summary']}"
      @account.save

      # Send notification to Discord
      send_discord_notification(analysis)

      Rails.logger.info("Account #{@account.id} has been flagged for security review")
    else
      Rails.logger.info("No security flag needed for account #{@account.id}")
    end
  end

  def send_discord_notification(analysis)
    webhook_url = ENV.fetch('DISCORD_SECURITY_WEBHOOK_URL', nil)

    if webhook_url.blank?
      Rails.logger.error('Cannot send Discord notification: No webhook URL configured')
      return
    end

    message = {
      embeds: [{
        title: '🚨 Security Alert: Account Flagged',
        color: 15_158_332, # Red color
        fields: [
          {
            name: 'Account ID',
            value: @account.id.to_s,
            inline: true
          },
          {
            name: 'Domain',
            value: @domain || 'N/A',
            inline: true
          },
          {
            name: 'User Email',
            value: @user&.email || 'N/A',
            inline: true
          },
          {
            name: 'Threat Level',
            value: analysis['threat_level'],
            inline: true
          },
          {
            name: 'Recommendation',
            value: analysis['recommendation'],
            inline: true
          },
          {
            name: 'Illegal Activities',
            value: analysis['illegal_activities_detected'] ? 'Yes' : 'No',
            inline: true
          },
          {
            name: 'Summary',
            value: analysis['threat_summary']
          }
        ],
        timestamp: Time.current.iso8601
      }]
    }

    HTTParty.post(
      webhook_url,
      body: message.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    Rails.logger.info("Discord notification sent for flagged account #{@account.id}")
  rescue StandardError => e
    Rails.logger.error("Error sending Discord notification: #{e.message}")
  end

  def sanitize_url(domain)
    url = "https://#{domain}" unless domain.start_with?('http://', 'https://')
    Rails.logger.info("Sanitized URL: #{url}")
    url
  end

  def llm_messages(content)
    Rails.logger.info('Preparing LLM messages for content analysis')
    [
      { role: 'system', content: 'You are a security analysis system that evaluates websites for potential threats and scams.' },
      { role: 'user', content: Internal::AccountAnalysis::PromptsService.threat_analyser(content) }
    ]
  end
end
