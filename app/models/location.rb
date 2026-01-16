# == Schema Information
#
# Table name: locations
#
#  id                 :bigint           not null, primary key
#  name               :string           not null
#  description        :text
#  type_name          :string
#  parent_location_id :bigint
#  account_id         :bigint           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_locations_on_account_id                      (account_id)
#  index_locations_on_account_id_and_name             (account_id, name)
#  index_locations_on_parent_location_id              (parent_location_id)
#  index_locations_on_parent_and_account              (parent_location_id, account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (parent_location_id => locations.id)
#

class Location < ApplicationRecord
  # Associations
  belongs_to :account
  belongs_to :parent_location,
             class_name: 'Location',
             optional: true,
             inverse_of: :child_locations

  has_many :child_locations,
           class_name: 'Location',
           foreign_key: :parent_location_id,
           dependent: :destroy,
           inverse_of: :parent_location

  has_one :address, as: :addressable, class_name: 'AccountAddress', dependent: :destroy
  has_many :account_users, dependent: :nullify
  has_many :conversations, dependent: :nullify

  # Nested attributes for creating/updating address in the same request
  accepts_nested_attributes_for :address, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :type_name, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }

  # Critical validation: prevent cycles in the hierarchy
  validate :cannot_be_its_own_ancestor

  # Scopes
  scope :root_locations, -> { where(parent_location_id: nil) }
  scope :with_parent, -> { where.not(parent_location_id: nil) }

  # Check if this location is a root (no parent)
  def root?
    parent_location_id.nil?
  end

  # Check if this location has children
  def children?
    child_locations.exists?
  end

  # Get all ancestors (parents, grandparents, etc.)
  def ancestors
    return [] if root?

    ancestors_list = []
    current = parent_location

    while current
      ancestors_list << current
      current = current.parent_location
    end

    ancestors_list
  end

  # Get all descendants (children, grandchildren, etc.) recursively
  def descendants
    child_locations.includes(:child_locations).flat_map do |child|
      [child] + child.descendants
    end
  end

  # Get this location and all its descendants as an ActiveRecord relation
  def with_descendants
    location_ids = [id] + descendants.map(&:id)
    self.class.where(id: location_ids)
  end

  # Get the level in the hierarchy (0 = root, 1 = child of root, etc.)
  def depth
    ancestors.count
  end

  # Full path of names (e.g., "Corporate > North Region > CDMX Branch")
  def full_path
    (ancestors.reverse.map(&:name) + [name]).join(' > ')
  end

  private

  # Critical validation to prevent circular references in hierarchy
  def cannot_be_its_own_ancestor
    return unless parent_location_id

    # Cannot be its own parent
    if parent_location_id == id
      errors.add(:parent_location_id, 'cannot be the location itself')
      return
    end

    # Check that it doesn't create a cycle
    return unless parent_location_id_changed?

    current = parent_location
    visited_ids = [id]

    while current
      if visited_ids.include?(current.id)
        errors.add(:parent_location_id, 'would create a circular reference')
        break
      end

      visited_ids << current.id
      current = current.parent_location
    end
  end
end
