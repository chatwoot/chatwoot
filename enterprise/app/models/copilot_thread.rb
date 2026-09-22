# == Schema Information
#
# Table name: copilot_threads
#
#  id           :bigint           not null, primary key
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  account_id   :bigint           not null
#  assistant_id :integer
#  user_id      :bigint           not null
#
# Indexes
#
#  index_copilot_threads_on_account_id    (account_id)
#  index_copilot_threads_on_assistant_id  (assistant_id)
#  index_copilot_threads_on_user_id       (user_id)
#
class CopilotThread < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :assistant, class_name: 'Captain::Assistant', optional: true
  has_many :copilot_messages, dependent: :destroy_async
  has_many :copilot_runs, dependent: :destroy

  validates :title, presence: true
  validates :assistant, presence: true, if: :legacy?
  enum engine: { legacy: 'legacy', v2: 'v2' }
  validate :engine_cannot_change, on: :update

  def push_event_data
    {
      id: id,
      title: title,
      created_at: created_at.to_i,
      user: user.push_event_data,
      account_id: account_id,
      engine: engine,
      execution_availability: execution_availability
    }
  end

  def execution_availability(run: nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    return { available: nil, reason: 'legacy_engine' } if legacy?

    reason = if !account.active?
               'account_inactive'
             elsif !account.account_users.exists?(user_id: user_id)
               'access_unavailable'
             elsif !account.feature_enabled?('copilot_v2')
               'feature_disabled'
             elsif run&.charged_at.nil? && !account.usage_limits.dig(:captain, :responses, :current_available).to_i.positive?
               'response_credits_unavailable'
             end
    { available: reason.nil?, reason: reason }
  end

  def previous_history
    copilot_messages
      .where(message_type: %w[user assistant])
      .order(created_at: :asc)
      .map do |copilot_message|
        {
          content: copilot_message.message['content'],
          role: copilot_message.message_type
        }
      end
  end

  private

  def engine_cannot_change
    errors.add(:engine, 'cannot be changed') if will_save_change_to_engine?
  end
end
