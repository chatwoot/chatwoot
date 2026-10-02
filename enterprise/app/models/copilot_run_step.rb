# == Schema Information
#
# Table name: copilot_run_steps
#
#  id             :bigint           not null, primary key
#  approval       :jsonb            not null
#  arguments      :jsonb            not null
#  attempts       :integer          default(0), not null
#  error          :string
#  name           :string           not null
#  result         :jsonb
#  status         :string           default("queued"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  call_id        :string           not null
#  copilot_run_id :bigint           not null
#
# Indexes
#
#  index_copilot_run_steps_on_copilot_run_id              (copilot_run_id)
#  index_copilot_run_steps_on_copilot_run_id_and_call_id  (copilot_run_id,call_id) UNIQUE
#
class CopilotRunStep < ApplicationRecord
  belongs_to :copilot_run

  validates :call_id, :name, presence: true
  validates :status, inclusion: { in: %w[queued running waiting_for_approval succeeded failed] }

  def receipt
    { step_id: id, name: name, status: status, arguments: arguments, result: result, error: error, attempts: attempts }
  end
end
