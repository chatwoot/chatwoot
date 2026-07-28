# == Schema Information
#
# Table name: flows
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE), not null
#  category    :string
#  description :text
#  exit_policy :jsonb            not null
#  graph       :jsonb            not null
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  account_id  :bigint           not null
#
class Flow < ApplicationRecord
  DEFAULT_EXIT_POLICY = {
    'on_complete' => { 'status' => 'resolved', 'assignee_mode' => 'none' },
    'on_handoff' => { 'status' => 'open', 'assignee_mode' => 'unassigned', 'private_note' => true },
    'on_fail' => { 'status' => 'open', 'assignee_mode' => 'unassigned', 'private_note' => true },
    'on_human_break' => { 'status' => 'open', 'assignee_mode' => 'keep' },
    'on_cancel' => { 'status' => 'open', 'assignee_mode' => 'keep' }
  }.freeze

  belongs_to :account
  has_many :flow_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :account_id }
  validate :validate_graph_schema

  scope :active, -> { where(active: true) }

  before_validation :ensure_exit_policy

  def entry_node
    return if graph.blank?

    graph['nodes']&.find { |n| n['id'] == graph['entry_node_id'] }
  end

  def find_node(node_id)
    graph['nodes']&.find { |n| n['id'] == node_id }
  end

  def edges_from(node_id)
    Array(graph['edges']).select { |e| e['from'] == node_id }
  end

  def resolved_exit_policy(event_key)
    policy = (exit_policy.presence || {}).with_indifferent_access
    defaults = DEFAULT_EXIT_POLICY.with_indifferent_access
    defaults[event_key].to_h.merge(policy[event_key].to_h)
  end

  private

  def ensure_exit_policy
    self.exit_policy = {} if exit_policy.nil?
    self.graph = {} if graph.nil?
  end

  def validate_graph_schema
    return if graph.blank?

    nodes = graph['nodes']
    unless nodes.is_a?(Array)
      errors.add(:graph, 'must include nodes array')
      return
    end

    # graph['ui'] (positions/viewport) is editor-only and ignored by the runtime.
    return if graph['entry_node_id'].blank?

    return if nodes.any? { |n| n['id'] == graph['entry_node_id'] }

    errors.add(:graph, 'entry_node_id must reference a node')
  end
end
