module AccessTokenable
  extend ActiveSupport::Concern
  included do
    has_one :access_token, as: :owner, dependent: :destroy
    after_create :create_access_token
  end

  def create_access_token
    AccessToken.create!(owner: self)
  end
end
