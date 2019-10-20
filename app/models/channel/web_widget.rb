module Channel
  class WebWidget < ApplicationRecord
    self.table_name = 'channel_web_widgets'

    belongs_to :account
    has_one :inbox, as: :channel, dependent: :destroy
  end
end
