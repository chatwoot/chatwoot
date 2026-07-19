class InternalConversation < ApplicationRecord
  belongs_to :account
  belongs_to :team
  has_many :internal_messages, dependent: :destroy

  validates :team_id, uniqueness: { scope: :account_id }
  validate :team_belongs_to_account

  def self.ensure_for!(account:, team:)
    find_or_create_by!(account: account, team: team)
  end

  def bump_activity!(preview:)
    # Always refresh preview; debounced stamp only for last_activity_at under burst traffic.
    should_touch_activity = Rails.cache.write(
      "internal_chat_activity:#{id}",
      true,
      expires_in: 10.seconds,
      unless_exist: true
    )

    attrs = {
      last_message_preview: preview.to_s.truncate(140),
      updated_at: Time.current
    }
    attrs[:last_activity_at] = Time.current if should_touch_activity || last_activity_at.blank?

    update_columns(attrs)
  end

  def push_event_data
    {
      id: id,
      account_id: account_id,
      team_id: team_id,
      team: team.present? ? { id: team.id, name: team.name } : nil,
      last_activity_at: last_activity_at&.to_i,
      last_message_preview: last_message_preview,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i
    }
  end

  private

  def team_belongs_to_account
    return if team.blank? || team.account_id == account_id

    errors.add(:team_id, 'must belong to the same account')
  end
end
