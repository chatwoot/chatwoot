class ContactMergeJob < ApplicationJob
  queue_as :high

  def perform(account, base_contact, mergee_contact)
    set_statement_timeout

    contact_merge_action = ContactMergeAction.new(
      account: account,
      base_contact: base_contact,
      mergee_contact: mergee_contact
    )
    contact_merge_action.perform
  end

  def set_statement_timeout
    ActiveRecord::Base.connection.execute("SET statement_timeout = '600s'")
  end
end
