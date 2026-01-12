# == Schema Information
#
# Table name: agent_activity_logs
#
#  id               :bigint           not null, primary key
#  duration_seconds :integer
#  ended_at         :datetime
#  started_at       :datetime         not null
#  status           :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  idx_on_account_id_started_at_ended_at_3411f4f064  (account_id,started_at,ended_at)
#  idx_on_account_id_user_id_started_at_d337db4160   (account_id,user_id,started_at)
#  index_agent_activity_logs_on_account_id           (account_id)
#  index_agent_activity_logs_on_user_id              (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class AgentActivityLog < ApplicationRecord
  belongs_to :account
  belongs_to :user

  validates :status, presence: true, inclusion: { in: %w[online busy offline] }
  validates :started_at, presence: true

  before_save :calculate_duration, if: :ended_at_changed?

  scope :in_period, ->(since, until_time) { where('started_at <= ? AND (ended_at IS NULL OR ended_at >= ?)', until_time, since) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_team, ->(team_id) { joins(user: :account_users).where(account_users: { team_id: team_id }) }
  scope :active_statuses, -> { where(status: %w[online busy]) }
  scope :by_status, ->(status) { where(status: status) }

  def self.close_open_logs(account_id, user_id, ended_at)
    where(account_id: account_id, user_id: user_id, ended_at: nil)
      .find_each do |log|
        log.update!(ended_at: ended_at)
      end
  end

  def active?
    status.in?(%w[online busy])
  end

  private

  def calculate_duration
    return unless ended_at && started_at

    self.duration_seconds = (ended_at - started_at).to_i
  end
end
