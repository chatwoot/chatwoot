module Channel
  class WebWidget < ApplicationRecord
    self.table_name = 'channel_web_widgets'

    validates :website_name, presence: true
    validates :website_url, presence: true

    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy
    has_secure_token :website_token
  end
end
