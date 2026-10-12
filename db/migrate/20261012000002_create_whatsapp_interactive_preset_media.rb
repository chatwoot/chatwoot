class CreateWhatsappInteractivePresetMedia < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_interactive_preset_media do |t|
      t.references :whatsapp_interactive_preset, null: false, foreign_key: true, index: { name: 'index_preset_media_on_preset_id' }
      t.integer :position, null: false
      t.timestamps
    end

    add_index :whatsapp_interactive_preset_media, [:whatsapp_interactive_preset_id, :position],
              unique: true, name: 'index_preset_media_on_preset_id_and_position'
  end
end
