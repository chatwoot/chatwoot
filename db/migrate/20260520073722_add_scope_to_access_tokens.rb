class AddScopeToAccessTokens < ActiveRecord::Migration[7.1]
  def change
    add_column :access_tokens, :scope, :string, default: 'full', null: false
  end
end
