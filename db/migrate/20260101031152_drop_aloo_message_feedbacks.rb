# frozen_string_literal: true

class DropAlooMessageFeedbacks < ActiveRecord::Migration[7.0]
  def change
    drop_table :aloo_message_feedbacks do |t|
      t.bigint :message_id, null: false
      t.bigint :aloo_memory_id
      t.bigint :user_id
      t.string :feedback_type, null: false
      t.text :comment
      t.timestamps
    end
  end
end
