class AddHideInputFlagToBotConfig < ActiveRecord::Migration[6.0]
  def change
    add_column :agent_bots, :hide_input_for_bot_conversations, :boolean, default: false
  end
end
