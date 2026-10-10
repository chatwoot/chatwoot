class Internal::DailyAgentLogoutJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    return unless ChatwootApp.enterprise?

    Account.where('settings @> ?', { daily_agent_logout: { enabled: true } }.to_json).find_each do |account|
      AgentSessions::DailyLogoutService.new(account: account).perform
    end
  end
end
