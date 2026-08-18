# == Schema Information
#
# Table name: ticket_tasks
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  description   :text
#  due_at        :datetime
#  status        :integer          default("open"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  assignee_id   :bigint
#  created_by_id :bigint
#  team_id       :bigint
#  ticket_id     :bigint           not null
#
# Indexes
#
#  index_ticket_tasks_on_account_id            (account_id)
#  index_ticket_tasks_on_assignee_id           (assignee_id)
#  index_ticket_tasks_on_created_by_id         (created_by_id)
#  index_ticket_tasks_on_team_id               (team_id)
#  index_ticket_tasks_on_ticket_id             (ticket_id)
#  index_ticket_tasks_on_ticket_id_and_status  (ticket_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (assignee_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (team_id => teams.id)
#  fk_rails_...  (ticket_id => tickets.id)
#

# Internal work item on a ticket, in the spirit of a Linear sub-issue. Never
# surfaced to the customer: it exists so "we replied" cannot pass for "we are done".
class TicketTask < ApplicationRecord
  belongs_to :account
  belongs_to :ticket
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :team, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  enum :status, { open: 0, done: 1 }

  validates :title, presence: true

  before_save :sync_completed_at
  after_update_commit :notify_task_completed

  def push_event_data
    {
      id: id,
      ticket_id: ticket_id,
      title: title,
      description: description,
      status: status,
      assignee_id: assignee_id,
      team_id: team_id,
      due_at: due_at&.iso8601,
      completed_at: completed_at&.iso8601
    }
  end

  private

  def sync_completed_at
    return unless status_changed?

    self.completed_at = done? ? Time.current : nil
  end

  def notify_task_completed
    return unless previous_changes.key?('status') && done?

    ::Conversations::ActivityMessageJob.perform_later(
      ticket.conversation,
      { account_id: account_id, inbox_id: ticket.conversation.inbox_id, message_type: :activity,
        content: I18n.t('conversations.activity.ticket.task_completed', title: title) }
    )
    Rails.configuration.dispatcher.dispatch(TICKET_TASK_COMPLETED, Time.zone.now, ticket_task: self)
  end
end
