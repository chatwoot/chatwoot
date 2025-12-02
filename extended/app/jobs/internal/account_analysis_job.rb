class Internal::AccountAnalysisJob < ApplicationJob
  queue_as :low

  def perform(account)
    # No-op: Threat analysis disabled in community edition
  end
end
