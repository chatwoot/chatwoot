class Internal::AccountAnalysisJob < ApplicationJob
  queue_as :within_10_minutes

  def perform(account)
    return unless ChatwootApp.chatwoot_cloud?

    Internal::AccountAnalysis::ThreatAnalyserService.new(account).perform
  end
end
