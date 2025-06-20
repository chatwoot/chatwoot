class CreateAccountPrompts < ActiveRecord::Migration[7.0]
  def change
    create_table :account_prompts, id: :uuid, if_not_exists: true do |t|
      t.references :account, type: :bigint, foreign_key: true
      t.string :prompt_key, null: false
      t.text :text, null: false

      t.timestamps
    end

    add_index :account_prompts, [:account_id, :prompt_key], unique: true, if_not_exists: true
  end
end