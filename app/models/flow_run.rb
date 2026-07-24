# == Schema Information
#
# Table name: flow_runs
#
#  id               :bigint           not null, primary key
#  current_node_id  :string
#  ended_at         :datetime
#  ended_reason     :string
#  started_at       :datetime
#  state            :integer          default("running"), not null
#  trail            :jsonb            not null
#  trigger          :string           default("automation_rule")
#  variables        :jsonb            not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  conversation_id  :bigint           not null
#  flow_id          :bigint           not null
#
class FlowRun < ApplicationRecord
  belongs_to :flow
  belongs_to :conversation
  belongs_to :account
  has_many :flow_events, dependent: :destroy

  enum state: { running: 0, waiting: 1, completed: 2, handed_off: 3, failed: 4, cancelled: 5 }

  validates :state, presence: true

  def current_node
    return if current_node_id.blank?

    flow.find_node(current_node_id)
  end

  def append_to_trail!(node_id, result = nil)
    entry = { 'node_id' => node_id, 'at' => Time.current.iso8601, 'result' => result }.compact
    update!(trail: Array(trail) + [entry])
  end

  def active?
    running? || waiting?
  end
end
