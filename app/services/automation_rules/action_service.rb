class AutomationRules::ActionService
  def initialize(rule, conversation)
    @rule = rule
    @conversation = conversation
    @account = @conversation.account
  end

  def perform
    @rule.actions.each do |action, _current_index|
      send(action[:action_name], action[:action_params])
    end
  end

  private

  def send_message(message)
    mb = Messages::MessageBuilder.new(@administrator, @conversation, { content: message, private: false })
    mb.perform
  end

  def assign_best_agents(agent_ids = []); end

  def add_label(labels = []); end

  def administrator
    @administrator ||= @account.administrators.first
  end
end
