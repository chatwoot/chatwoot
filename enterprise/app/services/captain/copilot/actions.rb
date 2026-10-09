# The changes Copilot can propose. Each one runs only after the agent approves it in the Copilot panel.
module Captain::Copilot::Actions
  def self.all
    [Captain::Copilot::Actions::AddLabels]
  end

  def self.build(name, account:, user:, arguments:)
    action = all.find { |candidate| name == candidate::NAME }
    raise ArgumentError, "Unknown action #{name}. Available actions: #{all.map { |candidate| candidate::NAME }.join(', ')}" unless action

    action.new(account: account, user: user, arguments: arguments)
  end
end
