class V2::AiAgents::AiAgentBaseBuilder
  attr_reader :account, :params

  def initialize(account, params, action)
    @account = account
    @params = params
    @action = action
  end

  def perform
    case @action
    when :create
      create
    when :update
      update
    when :destroy
      destroy
    else
      raise ArgumentError, "Unknown action: #{@action}"
    end
  rescue StandardError => e
    Rails.logger.error("❌ Error in AI Agent Builder: #{e.message}")
    raise e
  end
end
