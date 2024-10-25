class AddColReplyOnConnectWithTeamToChatbot < ActiveRecord::Migration[7.0]
  def change
    add_column :chatbots, :reply_on_connect_with_team, :string
  end
end
