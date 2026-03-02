class RemoveVoiceSubTogglesFromAlooAssistants < ActiveRecord::Migration[7.1]
  def up
    remove_index :aloo_assistants, :voice_input_enabled, if_exists: true
    remove_index :aloo_assistants, :voice_output_enabled, if_exists: true
    remove_column :aloo_assistants, :voice_input_enabled
    remove_column :aloo_assistants, :voice_output_enabled
  end

  def down
    add_column :aloo_assistants, :voice_input_enabled, :boolean, default: false
    add_column :aloo_assistants, :voice_output_enabled, :boolean, default: false
    add_index :aloo_assistants, :voice_input_enabled
    add_index :aloo_assistants, :voice_output_enabled
  end
end
