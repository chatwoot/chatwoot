class CreateCaptainRoutines < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_routines do |t|
      t.references :account, null: false, index: false
      t.string :name
      t.text :instructions, null: false
      t.jsonb :semantic_plan, null: false, default: {}
      t.jsonb :plan_evaluation, null: false, default: {}
      t.jsonb :dsl, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.jsonb :clarification_questions, null: false, default: []
      t.jsonb :clarification_answers, null: false, default: {}
      t.jsonb :evaluation, null: false, default: {}
      t.jsonb :build_log, null: false, default: []
      t.integer :build_iterations, null: false, default: 0

      t.timestamps
    end

    add_index :captain_routines, [:account_id, :status]
  end
end
