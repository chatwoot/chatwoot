class UserPinnedLabel < ApplicationRecord
  belongs_to :user
  belongs_to :label

  validates :user_id, uniqueness: { scope: :label_id }

  scope :ordered, -> { order(:position) }
end
