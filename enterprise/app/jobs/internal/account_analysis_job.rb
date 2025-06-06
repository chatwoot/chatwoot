class Internal::AccountAnalysisJob < ApplicationJob
  queue_as :low

  def perform(account)
    return if GlobalConfig.get_value('DEPLOYMENT_ENV') != 'cloud'

    Internal::AccountAnalysis::ThreatAnalyserService.new(account).perform
  end
end
