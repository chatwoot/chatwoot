class Channel::Widget < ApplicationRecord
  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy
end
