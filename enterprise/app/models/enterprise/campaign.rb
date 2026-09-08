module Enterprise::Campaign
  extend ActiveSupport::Concern

  included do
    has_many :campaign_recipients, dependent: :delete_all
  end
end
