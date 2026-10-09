# == Schema Information
#
# Table name: copilot_action_items
#
#  id             :bigint           not null, primary key
#  attempts       :integer          default(0), not null
#  error          :string
#  status         :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  copilot_run_id :bigint           not null
#  record_id      :bigint           not null
#
# Indexes
#
#  index_copilot_action_items_on_copilot_run_id                (copilot_run_id)
#  index_copilot_action_items_on_copilot_run_id_and_record_id  (copilot_run_id,record_id) UNIQUE
#
# One target of an approved action and what happened to it, so a retried job skips records that are already done.
class CopilotActionItem < ApplicationRecord
  belongs_to :copilot_run

  STATUSES = %w[applied skipped retry failed].freeze
  FINAL_STATUSES = %w[applied skipped failed].freeze

  validates :record_id, uniqueness: { scope: :copilot_run_id }
  validates :status, inclusion: { in: STATUSES }
end
