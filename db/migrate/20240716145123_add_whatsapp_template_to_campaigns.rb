class AddWhatsappTemplateToCampaigns < ActiveRecord::Migration[7.0]
  def change
    add_column :campaigns, :whatsapp_template, :string
  end
end
