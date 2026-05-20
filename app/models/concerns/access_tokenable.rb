module AccessTokenable
  extend ActiveSupport::Concern
  # AccessToken is polymorphic and the table allows many rows per owner. By
  # convention we expose at most two per User (one `full`, one `read_only`);
  # AgentBot and PlatformApp keep their single `full` token. The scoped
  # has_one below is what makes `owner.access_token` deterministic.
  included do
    has_one :access_token, -> { where(scope: 'full') },
            as: :owner, class_name: 'AccessToken', inverse_of: :owner, dependent: :destroy_async
    after_create :create_access_token
  end

  def create_access_token
    AccessToken.create!(owner: self, scope: 'full')
  end
end
