class CreateMessageQualityScores < ActiveRecord::Migration[7.0]
  def change
    create_table :message_quality_scores do |t|
      t.references :message, null: false, foreign_key: true
      t.jsonb :scores, null: false, default: {}
      t.timestamps
    end
  end
end
