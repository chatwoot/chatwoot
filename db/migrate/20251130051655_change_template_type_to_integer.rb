class ChangeTemplateTypeToInteger < ActiveRecord::Migration[7.1]
  def up
    # 1. Advanced Email Templates
    # Convert 'layout' -> 0, anything else (content) -> 1
    change_column :advanced_email_templates, :template_type, :integer,
                  using: "CASE template_type WHEN 'layout' THEN 0 ELSE 1 END",
                  default: 1,
                  null: false

    # 2. Account Email Templates
    change_column :account_email_templates, :template_type, :integer,
                  using: "CASE template_type WHEN 'layout' THEN 0 ELSE 1 END",
                  default: 1,
                  null: false

    # 3. Global Email Templates
    change_column :global_email_templates, :template_type, :integer,
                  using: "CASE template_type WHEN 'layout' THEN 0 ELSE 1 END",
                  default: 1,
                  null: false
  end

  def down
    change_column :advanced_email_templates, :template_type, :string
    change_column :account_email_templates, :template_type, :string
    change_column :global_email_templates, :template_type, :string
  end
end
