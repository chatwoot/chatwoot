class AutomationActionJob < ApplicationJob
  queue_as :default

  def perform(rule, account, conversation, contact, changed_attributes)
    ::AutomationRules::ActionService.new(rule, account, conversation, contact, changed_attributes).perform
  end
end
