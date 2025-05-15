class AddCsatConfigToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :csat_config, :jsonb, default: {
      display_type: 'emoji',
      message: '',
      survey_rules: {}
    }, null: false
  end
end
