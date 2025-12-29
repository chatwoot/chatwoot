class CreateLeadFollowUpSequences < ActiveRecord::Migration[7.1]
  def change
    create_table :lead_follow_up_sequences do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true

      t.string :name, null: false
      t.text :description
      t.boolean :active, default: false, null: false

      # Condiciones para auto-enrollment
      t.jsonb :trigger_conditions, default: {}

      # Pasos de la secuencia
      t.jsonb :steps, default: [], null: false

      # Configuración global
      t.jsonb :settings, default: {}

      # Estadísticas
      t.jsonb :stats, default: {}

      t.timestamps
    end

    add_index :lead_follow_up_sequences, [:account_id, :active]
  end
end
