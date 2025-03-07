class AddSlackMentionToUserAndTeam < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :slack_mention_code, :string, after: :email
    add_column :teams, :slack_mention_code, :string, after: :account_id
  end
end
