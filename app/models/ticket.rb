# == Schema Information
#
# Table name: tickets
#
#  id              :bigint           not null, primary key
#  closed_at       :datetime
#  due_at          :datetime
#  subject         :string           not null
#  ticket_type     :string
#  waiting_note    :string
#  waiting_on      :integer          default("none"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  created_by_id   :bigint
#
# Indexes
#
#  index_tickets_on_account_id       (account_id)
#  index_tickets_on_conversation_id  (conversation_id) UNIQUE
#  index_tickets_on_created_by_id    (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (conversation_id => conversations.id)
#  fk_rails_...  (created_by_id => users.id)
#

# The case layer on top of a conversation. A conversation is the customer-facing
# thread; the ticket is what the team owes the customer, and it is only done once
# its internal tasks are done. See Conversation#validate_ticket_status_transition.
class Ticket < ApplicationRecord
  WAITING_STATES = { none: 0, customer: 1, internal: 2, external: 3 }.freeze
  # Presentation buckets derived from the conversation and the ticket. Not
  # persisted: the conversation stays the single source of truth for status.
  STATUS_CATEGORIES = %w[triage in_progress waiting done closed].freeze
  # The dashboard picker offers these; the column itself stays free-form.
  TYPES = %w[question issue request incident].freeze
  # Only these carry enough meaning for a listener to act on an update.
  DISPATCHABLE_ATTRIBUTES = %w[subject ticket_type waiting_on waiting_note due_at closed_at].freeze

  # SQL approximations of #status_category. The category is derived in Ruby, so
  # it cannot be selected on directly.
  TRIAGE_CONDITION = 'conversations.status = :open AND conversations.assignee_id IS NULL AND conversations.assignee_agent_bot_id IS NULL'.freeze
  STATUS_CATEGORY_CONDITIONS = {
    'closed' => 'conversations.status = :resolved AND tickets.closed_at IS NOT NULL',
    'done' => 'conversations.status = :resolved AND tickets.closed_at IS NULL',
    'waiting' => 'conversations.status != :resolved AND (tickets.waiting_on != :waiting_none OR conversations.status = :snoozed)',
    'triage' => "tickets.waiting_on = :waiting_none AND #{TRIAGE_CONDITION}",
    'in_progress' => "conversations.status NOT IN (:resolved, :snoozed) AND tickets.waiting_on = :waiting_none AND NOT (#{TRIAGE_CONDITION})"
  }.freeze

  belongs_to :account
  belongs_to :conversation
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :ticket_tasks, dependent: :destroy

  # `none` would collide with Enumerable#none?, so the predicates are prefixed.
  enum :waiting_on, WAITING_STATES, prefix: :waiting

  validates :subject, presence: true
  validates :conversation_id, uniqueness: true

  after_create_commit :notify_ticket_created
  after_update_commit :notify_ticket_updated

  # Everything the team still owes the customer: `done` and `closed` are exactly
  # the categories a resolved conversation produces.
  scope :unsettled, -> { joins(:conversation).where.not(conversations: { status: Conversation.statuses[:resolved] }) }

  def self.with_status_category(category)
    return none unless STATUS_CATEGORIES.include?(category)

    joins(:conversation).where(
      STATUS_CATEGORY_CONDITIONS[category],
      resolved: Conversation.statuses[:resolved],
      open: Conversation.statuses[:open],
      snoozed: Conversation.statuses[:snoozed],
      waiting_none: WAITING_STATES[:none]
    )
  end

  def status_category
    return closed_at.present? ? 'closed' : 'done' if conversation.resolved?
    return 'waiting' if !waiting_none? || conversation.snoozed?

    untriaged? ? 'triage' : 'in_progress'
  end

  def open_tasks_count
    ticket_tasks.loaded? ? ticket_tasks.count(&:open?) : ticket_tasks.open.count
  end

  def push_event_data
    {
      id: id,
      conversation_id: conversation.display_id,
      subject: subject,
      ticket_type: ticket_type,
      status_category: status_category,
      waiting_on: waiting_on,
      waiting_note: waiting_note,
      due_at: due_at&.iso8601,
      closed_at: closed_at&.iso8601,
      open_tasks_count: open_tasks_count
    }
  end

  # Slimmed conversation context: the full conversation webhook payload drags in
  # messages and contact data a ticket subscriber has no use for.
  def webhook_data
    push_event_data.merge(
      account: account.webhook_data,
      conversation: {
        id: conversation.display_id,
        inbox_id: conversation.inbox_id,
        status: conversation.status
      }
    )
  end

  private

  # Nobody has picked the case up yet: still open with neither an agent nor a bot on it.
  def untriaged?
    conversation.open? && conversation.assignee_id.blank? && conversation.assignee_agent_bot_id.blank?
  end

  def notify_ticket_created
    create_activity_message(I18n.t('conversations.activity.ticket.created', subject: subject))
    dispatcher_dispatch(TICKET_CREATED)
  end

  def notify_ticket_updated
    return unless previous_changes.keys.intersect?(DISPATCHABLE_ATTRIBUTES)

    create_waiting_on_activity if previous_changes.key?('waiting_on')
    dispatcher_dispatch(TICKET_UPDATED, previous_changes)
  end

  def create_waiting_on_activity
    content = if waiting_none?
                I18n.t('conversations.activity.ticket.waiting_cleared')
              else
                I18n.t('conversations.activity.ticket.waiting_on', waiting_on: waiting_on)
              end

    create_activity_message(content)
  end

  def create_activity_message(content)
    ::Conversations::ActivityMessageJob.perform_later(
      conversation,
      { account_id: account_id, inbox_id: conversation.inbox_id, message_type: :activity, content: content }
    )
  end

  def dispatcher_dispatch(event_name, changed_attributes = nil)
    Rails.configuration.dispatcher.dispatch(event_name, Time.zone.now, ticket: self, changed_attributes: changed_attributes)
  end
end
