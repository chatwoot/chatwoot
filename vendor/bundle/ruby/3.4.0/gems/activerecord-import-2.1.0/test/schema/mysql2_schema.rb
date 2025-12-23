# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :books, force: :cascade do |t|
    t.string :title, null: false
    t.virtual :upper_title, type: :string, as: "upper(`title`)" if t.respond_to?(:virtual)
    t.string :publisher, null: false, default: 'Default Publisher'
    t.string :author_name, null: false
    t.datetime :created_at
    t.datetime :created_on
    t.datetime :updated_at
    t.datetime :updated_on
    t.date :publish_date
    t.integer :topic_id
    t.integer :tag_id
    t.integer :publisher_id
    t.boolean :for_sale, default: true
    t.integer :status, default: 0
    t.string :type
  end
end
