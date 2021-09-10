module AccessTokenable
  extend ActiveSupport::Concern
  included do
      validates :account_id, presence: true
  belongs_to :account
  has_one :inbox, as: :channel, dependent: :destroy
  end

  def create_access_token
    AccessToken.create!(owner: self)
  end
end
