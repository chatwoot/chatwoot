# == Schema Information
#
# Table name: copilot_pending_admin_actions
#
#  id                :bigint           not null, primary key
#  action_params     :jsonb            not null
#  status            :integer          default("pending"), not null
#  tool_name         :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  copilot_thread_id :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  idx_on_copilot_thread_id_status_da15169c7c                (copilot_thread_id,status)
#  index_copilot_pending_admin_actions_on_account_id         (account_id)
#  index_copilot_pending_admin_actions_on_copilot_thread_id  (copilot_thread_id)
#  index_copilot_pending_admin_actions_on_user_id            (user_id)
#
class CopilotPendingAdminAction < ApplicationRecord
  belongs_to :account
  belongs_to :user
  belongs_to :copilot_thread

  enum status: { pending: 0, confirmed: 1, rejected: 2, expired: 3 }

  validates :tool_name, presence: true

  before_create :expire_existing_pending_actions

  def summary
    I18n.t(
      "captain.copilot_pending_admin_actions.tools.#{tool_name}",
      default: tool_name.humanize,
      **action_params.symbolize_keys
    )
  end

  def push_event_data
    {
      id: id,
      tool_name: tool_name,
      action_params: action_params,
      status: status,
      summary: summary,
      created_at: created_at.to_i,
      copilot_thread_id: copilot_thread_id
    }
  end

  private

  def expire_existing_pending_actions
    copilot_thread.copilot_pending_admin_actions.pending.update_all(status: self.class.statuses[:expired])
  end
end
