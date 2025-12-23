class Post < ApplicationRecord
  has_one_attached :cover_image
  has_many_attached :other_images

  validates :title, presence: true
end
