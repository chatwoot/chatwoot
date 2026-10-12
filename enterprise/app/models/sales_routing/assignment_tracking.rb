module SalesRouting::AssignmentTracking
  extend ActiveSupport::Concern

  included do
    has_many :conversation_assignment_events, dependent: :delete_all
    after_save :record_assignment_event, if: :assignment_ledger_enabled?
  end

  private

  def record_assignment_event
    return unless saved_change_to_assignee_id? && assignee_id.present?

    route = additional_attributes.fetch(SalesRouting::Classifier::ATTRIBUTES_KEY, {})
    first_message = messages.incoming.where(private: false).minimum(:created_at)
    reassignment = assignee_id_before_last_save.present? || conversation_assignment_events.exists?
    conversation_assignment_events.create!(
      account: account, inbox_id: inbox_id, conversation_display_id: display_id, agent_id: assignee_id, agent_name: assignee.name,
      event_kind: reassignment ? 'reassignment' : 'initial', source: Current.executed_by.is_a?(AssignmentPolicy) ? 'automatic' : 'manual',
      routing: route, first_customer_message_at: first_message, assigned_at: Time.current
    )
  end

  def assignment_ledger_enabled?
    account.internal_attributes.dig('assignment_ledger', 'inbox_ids')&.include?(inbox_id)
  end
end
