module Enterprise::Concerns::Contact
  extend ActiveSupport::Concern
  included do
    has_many :campaign_recipients, dependent: :destroy_async
  end
end
