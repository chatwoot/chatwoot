class AddScopeToAccessTokens < ActiveRecord::Migration[7.1]
  def change
    add_column :access_tokens, :scope, :string, default: 'full', null: false
    add_index :access_tokens, [:owner_type, :owner_id, :scope],
              unique: true,
              name: 'index_access_tokens_on_owner_and_scope'
  end
end
