class SendContactUpdateOnSlackJob < ApplicationJob
  queue_as :low

  def perform(contact, hook, changed_attributes = {})
    return unless changed_attributes.key?('email')

    Integrations::Slack::SendContactUpdateService.new(
      contact: contact,
      hook: hook,
      changed_attributes: changed_attributes
    ).perform
  end
end
