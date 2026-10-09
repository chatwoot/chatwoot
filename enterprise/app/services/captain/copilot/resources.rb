# The record types Copilot can select with get_data. Each type owns its permission scope, filters, display columns
# and the queries that reach it from another saved set, so the model never writes a query or a join.
module Captain::Copilot::Resources
  def self.all
    [Captain::Copilot::Resources::Conversations, Captain::Copilot::Resources::Contacts, Captain::Copilot::Resources::Messages]
  end

  def self.build(name, account:, user:)
    resource = all.find { |candidate| name == candidate::NAME }
    raise ArgumentError, "Unknown resource #{name}. Available resources: #{all.map { |candidate| candidate::NAME }.join(', ')}" unless resource

    resource.new(account: account, user: user)
  end
end
