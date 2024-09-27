class RefreshAdminUserToken < ActiveRecord::Migration[7.0]
  def change
    useradmin = User.find_by(id: 3)
    useradmin.access_token.regenerate_token if useradmin
  end
end
