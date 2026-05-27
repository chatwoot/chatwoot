class AddAdditionalAttributesToCompanies < ActiveRecord::Migration[7.1]
  def change
    change_table :companies, bulk: true do |t|
      t.jsonb :additional_attributes, default: {}
      t.jsonb :custom_attributes, default: {}
      t.datetime :last_activity_at, precision: nil
    end
  end
end
