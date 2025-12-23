class CreateBrandingConfigs < ActiveRecord::Migration[7.1]
  def change
    create_table :branding_configs do |t|
      t.string :brand_name, default: 'SynkiCRM', null: false
      t.string :brand_website, default: 'https://synkicrm.com.br/', null: false
      t.string :support_email, default: 'suporte@synkicrm.com.br', null: false

      t.timestamps
    end

    # Create singleton record
    execute <<-SQL
      INSERT INTO branding_configs (brand_name, brand_website, support_email, created_at, updated_at)
      VALUES ('SynkiCRM', 'https://synkicrm.com.br/', 'suporte@synkicrm.com.br', NOW(), NOW())
    SQL
  end
end
