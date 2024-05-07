class CreateSmartActions < ActiveRecord::Migration[7.0]
  def change
    create_table :smart_actions, force: :cascade do |t|
      t.references :conversation, index: true, null: false
      t.references :message, index: true, null: false
      t.string :name
      t.string :label
      t.string :description
      t.string :event
      t.string :intent_type
      t.jsonb :custom_attributes, default: {}

      t.timestamps
    end
  end
end
