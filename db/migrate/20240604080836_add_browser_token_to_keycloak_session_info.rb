class AddBrowserTokenToKeycloakSessionInfo < ActiveRecord::Migration[7.0]
  def change
    remove_column :keycloak_session_infos, :email
    remove_column :keycloak_session_infos, :session_state
    add_column :keycloak_session_infos, :browser_token, :string, unique: true
    rename_column :keycloak_session_infos, :token_info, :metadata
  end
end
