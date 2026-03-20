class Internal::AccountAnalysis::AccountUpdaterService
  def initialize(account)
    @account = account
  end

  def update_with_analysis(analysis, error_message = nil)
    if error_message
      save_error(error_message)
      notify_on_discord
      return
    end

    save_analysis_results(analysis)
    flag_account_if_needed(analysis)
  end

  private

  def save_error(error_message)
    @account.internal_attributes['security_flagged'] = true
    @account.internal_attributes['security_flag_reason'] = "Error: #{error_message}"
    @account.save!
  end

  def save_analysis_results(analysis)
    @account.internal_attributes['last_threat_scan_at'] = Time.current
    @account.internal_attributes['last_threat_scan_level'] = analysis['threat_level']
    @account.internal_attributes['last_threat_scan_summary'] = analysis['threat_summary']
    @account.internal_attributes['last_threat_scan_recommendation'] = analysis['recommendation']
    @account.save!
  end

  def flag_account_if_needed(analysis)
    return if analysis['threat_level'] == 'none'

    if %w[high medium].include?(analysis['threat_level']) ||
       analysis['illegal_activities_detected'] == true ||
       analysis['recommendation'] == 'block'

      @account.internal_attributes['security_flagged'] = true
      @account.internal_attributes['security_flag_reason'] = "Threat detected: #{analysis['threat_summary']}"
      @account.save!

      Rails.logger.info("Flagging account #{@account.id} due to threat level: #{analysis['threat_level']}")
    end

    notify_on_discord
  end

  def notify_on_discord
    Rails.logger.info("Account #{@account.id} has been flagged for security review")
    Internal::AccountAnalysis::DiscordNotifierService.new.notify_flagged_account(@account)
  end
end
