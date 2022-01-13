class RemovePlatformAppPermissibleAccessTokens < ActiveRecord::Migration[6.1]
  def change
    AccessToken.where(owner_type: 'PlatformAppPermissible').destroy_all
  end
end
