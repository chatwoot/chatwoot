module Dashassist
  class ShopifyStore < ApplicationRecord
    belongs_to :account
    belongs_to :inbox

    validates :shop, presence: true, uniqueness: true
    validates :account_id, presence: true
    validates :enabled, inclusion: { in: [true, false] }

    attribute :enabled, :boolean, default: true
  end
end 