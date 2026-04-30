# frozen_string_literal: true

class Task < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :creator, class_name: 'User'
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :agent_bot, class_name: 'AgentBot', optional: true

  # Enums
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  enum action_type: {
    general: 0,
    schedule_appointment: 1,
    send_message: 3,
    assign_conversation: 4
  }

  # Callbacks
  after_commit :notify_agent_bot, if: :agent_bot_id?

  # Validations
  validates :title, presence: true
  validates :status, presence: true
  validate :only_one_agent_type

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :by_entity, ->(type, id) { where(entity_type: type, entity_id: id) }
  scope :due_for_execution, -> { pending.where('scheduled_at <= ?', Time.current).where.not(scheduled_at: nil) }

  private

  def only_one_agent_type
    return unless assignee_id.present? && agent_bot_id.present?

    errors.add(:base, 'Cannot assign both a human agent and an agent bot')
  end

  def notify_agent_bot
    return if agent_bot.outgoing_url.blank?

    payload = {
      event: 'task_assigned',
      task: {
        id: id,
        title: title,
        description: description,
        status: status,
        action_type: action_type,
        scheduled_at: scheduled_at,
        execution_config: execution_config,
        entity_type: entity_type,
        entity_id: entity_id,
        assignee_id: assignee_id,
        agent_bot_id: agent_bot_id,
        creator_id: creator_id,
        account_id: account_id,
        created_at: created_at,
        updated_at: updated_at,
        creator: creator && { id: creator.id, name: creator.name, avatar_url: creator.avatar_url },
        assignee: assignee && { id: assignee.id, name: assignee.name, avatar_url: assignee.avatar_url },
        agent_bot: { id: agent_bot.id, name: agent_bot.name, outgoing_url: agent_bot.outgoing_url }
      }
    }
    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end
end
