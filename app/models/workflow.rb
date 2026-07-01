class Workflow < ApplicationRecord
  belongs_to :account

  validates :name, presence: true
  validates :trigger_event, presence: true
  validate :validate_nodes_structure
  validate :validate_edges_structure

  scope :active, -> { where(active: true) }

  private

  def validate_nodes_structure
    unless nodes.is_a?(Array)
      errors.add(:nodes, 'must be an array')
      return
    end

    nodes.each do |node|
      unless node.is_a?(Hash) && node['id'].present? && node['type'].present?
        errors.add(:nodes, 'each node must have an id and type')
        break
      end
    end
  end

  def validate_edges_structure
    unless edges.is_a?(Array)
      errors.add(:edges, 'must be an array')
      return
    end

    edges.each do |edge|
      unless edge.is_a?(Hash) && edge['id'].present? && edge['source'].present? && edge['target'].present?
        errors.add(:edges, 'each edge must have an id, source, and target')
        break
      end
    end
  end
end
