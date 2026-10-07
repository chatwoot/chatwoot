class ChangeCaptainAssistantDescriptionToText < ActiveRecord::Migration[7.0]
  def up
    change_column :captain_assistants, :description, :text
  end

  def down
    change_column :captain_assistants, :description, :string
  end
end
