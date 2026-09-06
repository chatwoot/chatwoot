module ReportHelper
  extend ActiveSupport::Concern

  included do
    include ReportHelper::ConversationMetrics
    include ReportHelper::BotMetrics
    include ReportHelper::ResponseTimeMetrics
  end

  private

  def scope
    case params[:type]
    when :account then account
    when :inbox   then inbox
    when :agent   then user
    when :label   then label
    when :team    then team
    when :agent_bot then agent_bot
    end
  end

  def agent_bot
    scope.agent_bots.where(account_id: account.id)
  end
end
