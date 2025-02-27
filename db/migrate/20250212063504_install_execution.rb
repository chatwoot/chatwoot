class InstallExecution < ActiveRecord::Migration[7.0]
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def change
    create_table :rails_execution_tasks, force: true do |t|
      t.timestamps null: false
      t.column :scheduled_at, :datetime
      t.column :title, :string, null: false
      t.column :status, :string, null: false
      t.column :syntax_status, :string, default: 'bad'
      t.column :description, :text
      t.column :script, :text
      t.column :owner_type, :string
      t.column :owner_id, :integer
      t.column :repeat_mode, :string, default: 'none'
      t.column :jid, :string
    end
    add_index :rails_execution_tasks, :status
    add_index :rails_execution_tasks, %i[owner_id owner_type], name: :tasks_owner_index

    create_table :rails_execution_labels do |t|
      t.timestamps
      t.column :name, :string
    end

    add_index :rails_execution_labels, :name, unique: true

    create_table :rails_execution_comments, force: true do |t|
      t.timestamps null: false
      t.column :task_id, :integer, null: false
      t.column :content, :text, null: false
      t.column :owner_id, :integer
      t.column :owner_type, :string
    end
    add_index :rails_execution_comments, :task_id
    add_index :rails_execution_comments, %i[owner_id owner_type], name: :comments_owner_index

    create_table :rails_execution_activities, force: true do |t|
      t.timestamps null: false
      t.column :task_id, :integer, null: false
      t.column :message, :text, null: false
      t.column :owner_id, :integer
      t.column :owner_type, :string
    end
    add_index :rails_execution_activities, :task_id
    add_index :rails_execution_activities, %i[owner_id owner_type], name: :activities_owner_index

    create_table :rails_execution_task_reviews, force: true do |t|
      t.timestamps null: false
      t.column :task_id, :integer, null: false
      t.column :status, :text, null: false
      t.column :owner_id, :integer
      t.column :owner_type, :string
    end
    add_index :rails_execution_task_reviews, :task_id
    add_index :rails_execution_task_reviews, %i[owner_id owner_type], name: :reviews_owner_index

    create_table :rails_execution_task_labels, force: true do |t|
      t.timestamps null: false
      t.column :task_id, :integer, null: false
      t.column :label_id, :integer, null: false
    end

    add_index :rails_execution_task_labels, :task_id
    add_index :rails_execution_task_labels, :label_id
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
