class Internal::AccountAnalysis::DiscordNotifierService
  def notify_flagged_account(account)
    if webhook_url.blank?
      Rails.logger.error('Cannot send Discord notification: No webhook URL configured')
      return
    end

    HTTParty.post(
      webhook_url,
      body: build_message(account).to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    Rails.logger.info("Discord notification sent for flagged account #{account.id}")
  rescue StandardError => e
    Rails.logger.error("Error sending Discord notification: #{e.message}")
  end

  private

  def build_message(account)
    analysis = account.internal_attributes
    user = account.users.order(id: :asc).first

    content = <<~MESSAGE
      ---
      An account has been flagged in our security system with the following details:

      🆔 **Account Details:**
      Account ID: #{account.id}
      User Email: #{user&.email || 'N/A'}
      Threat Level: #{analysis['last_threat_scan_level']}

      🔎 **System Recommendation:** #{analysis['last_threat_scan_recommendation']}
      #{analysis['illegal_activities_detected'] ? '⚠️ Potential illegal activities detected' : 'No illegal activities detected'}

      📝 **Findings:**
      #{analysis['last_threat_scan_summary']}
    MESSAGE

    { content: content }
  end

  def webhook_url
    @webhook_url ||= InstallationConfig.find_by(name: 'ACCOUNT_SECURITY_NOTIFICATION_WEBHOOK_URL')&.value
  end
end
