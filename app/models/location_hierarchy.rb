class LocationHierarchy < ApplicationRecord
  belongs_to :parent_location, class_name: 'Location'
  belongs_to :child_location, class_name: 'Location'
  belongs_to :account

  validates :parent_location_id, uniqueness: { scope: :child_location_id }
end
