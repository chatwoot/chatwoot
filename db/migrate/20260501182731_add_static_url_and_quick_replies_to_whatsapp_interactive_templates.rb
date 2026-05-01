class AddStaticUrlAndQuickRepliesToWhatsappInteractiveTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :whatsapp_interactive_templates, :static_url, :text
    add_column :whatsapp_interactive_templates, :quick_replies, :jsonb, null: false, default: []
  end
end
