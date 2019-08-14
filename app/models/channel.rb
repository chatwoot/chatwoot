class Channel < ApplicationRecord
  belongs_to :inbox
  has_many :conversations
end
