class CreateKeycloakSessionInfos < ActiveRecord::Migration[7.0]
  def change
    create_table :keycloak_session_infos do |t|
      t.string :email
      t.string :session_state
      t.json :token_info

      t.timestamps
    end
  end
end
