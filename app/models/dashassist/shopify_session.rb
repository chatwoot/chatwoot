module Dashassist
  def self.table_name_prefix
    'dashassist_'
  end

  class ShopifySession < ApplicationRecord
    validates :shop, presence: true, uniqueness: true
    validates :access_token, presence: true
    validates :expires_at, presence: true
    validates :scope, presence: true
  
    def expired?
      expires_at < Time.current
    end

    def self.create_or_update!(attributes)
      session = find_by(shop: attributes[:shop])
      if session
        session.update!(attributes)
        session
      else
        create!(attributes)
      end
    end
  end
end 