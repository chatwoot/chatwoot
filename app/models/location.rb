# == Schema Information
#
# Table name: locations
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :text
#  type_name   :string
#  account_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_locations_on_account_id           (account_id)
#  index_locations_on_account_id_and_name  (account_id, name)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#

class Location < ApplicationRecord
  # Associations
  belongs_to :account

  has_many :location_hierarchies_as_child,
           class_name: 'LocationHierarchy',
           foreign_key: :child_location_id,
           dependent: :destroy,
           inverse_of: :child_location

  has_many :location_hierarchies_as_parent,
           class_name: 'LocationHierarchy',
           foreign_key: :parent_location_id,
           dependent: :destroy,
           inverse_of: :parent_location

  has_many :parent_locations,
           through: :location_hierarchies_as_child,
           source: :parent_location

  has_many :child_locations,
           through: :location_hierarchies_as_parent,
           source: :child_location

  has_one :address, as: :addressable, class_name: 'AccountAddress', dependent: :destroy
  has_many :account_users, dependent: :nullify
  has_many :conversations, dependent: :nullify

  # Nested attributes for creating/updating address in the same request
  accepts_nested_attributes_for :address, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :type_name, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }

  # Critical validation: prevent self-referencing
  validate :cannot_be_its_own_ancestor

  # Scopes
  scope :root_locations, -> { where.not(id: LocationHierarchy.select(:child_location_id)) }
  scope :with_parent, -> { where(id: LocationHierarchy.select(:child_location_id)) }

  # Check if this location is a root (no parent)
  def root?
    parent_locations.empty?
  end

  # Check if this location has children
  def children?
    child_locations.exists?
  end

  # Get all ancestors (parents, grandparents, etc.) via BFS to handle DAG
  def ancestors
    visited = Set.new
    queue = parent_locations.to_a
    result = []

    while queue.any?
      current = queue.shift
      next if visited.include?(current.id)

      visited.add(current.id)
      result << current
      queue.concat(current.parent_locations.to_a)
    end

    result
  end

  # Get all descendants (children, grandchildren, etc.) via BFS
  def descendants
    visited = Set.new
    queue = child_locations.to_a
    result = []

    while queue.any?
      current = queue.shift
      next if visited.include?(current.id)

      visited.add(current.id)
      result << current
      queue.concat(current.child_locations.to_a)
    end

    result
  end

  # Get this location and all its descendants as an ActiveRecord relation
  def with_descendants
    location_ids = [id] + descendants.map(&:id)
    self.class.where(id: location_ids)
  end

  private

  # Prevent a location from being its own parent
  def cannot_be_its_own_ancestor
    return unless parent_locations.exists?(id: id)

    errors.add(:base, 'cannot be its own parent')
  end
end
