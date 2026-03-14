class CreateWhatsappInteractiveTemplates < ActiveRecord::Migration[7.0]
  def change
    create_table :whatsapp_interactive_templates do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.string :template_type, null: false, default: 'cta_url'
      t.string :header_type, null: false, default: 'none'
      t.string :header_text
      t.text :header_image_url
      t.text :body_text, null: false
      t.string :footer_text
      t.string :button_text, null: false
      t.string :url_placeholder, null: false, default: '__CTA_URL__'
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end

    add_index :whatsapp_interactive_templates,
              [:account_id, :name],
              unique: true,
              name: 'index_whatsapp_interactive_templates_on_account_id_and_name'
  end
end
