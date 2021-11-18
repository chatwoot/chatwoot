class AutomationRule::ActionService
  def initialize(rule, conversation)
    @rule = rule
    @conversation = conversation
  end

  def perform
    @rule.actions.each do |action, current_index|
      # check action and perform
    end
  end
end
