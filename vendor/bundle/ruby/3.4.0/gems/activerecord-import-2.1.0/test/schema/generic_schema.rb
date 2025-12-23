# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :schema_info, force: :cascade do |t|
    t.integer :version
  end
  add_index :schema_info, :version, unique: true

  SchemaInfo.create version: SchemaInfo::VERSION

  create_table :group, force: :cascade do |t|
    t.string :order
    t.timestamps null: true
  end

  create_table :topics, force: :cascade do |t|
    t.string :title, null: false
    t.string :author_name
    t.string :author_email_address
    t.datetime :written_on
    t.time :bonus_time
    t.datetime :last_read
    t.text :content
    t.boolean :approved, default: '1'
    t.integer :replies_count
    t.integer :parent_id
    t.integer :priority, default: 0
    t.string :type
    t.datetime :created_at
    t.datetime :created_on
    t.datetime :updated_at
    t.datetime :updated_on
  end

  create_table :projects, force: :cascade do |t|
    t.string :name
    t.string :type
  end

  create_table :developers, force: :cascade do |t|
    t.string :name
    t.integer :salary, default: '70000'
    t.datetime :created_at
    t.integer :team_id
    t.datetime :updated_at
  end

  create_table :addresses, force: :cascade do |t|
    t.string :address
    t.string :city
    t.string :state
    t.string :zip
    t.integer :developer_id
  end

  create_table :teams, force: :cascade do |t|
    t.string :name
  end

  create_table :cards, force: :cascade do |t|
    t.string :name
    t.string :deck_type
    t.integer :deck_id
  end

  create_table :decks, force: :cascade do |t|
    t.string :name
  end

  create_table :playing_cards, force: :cascade do |t|
    t.string :name
  end

  create_table :books, force: :cascade do |t|
    t.string :title, null: false
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

  create_table :chapters, force: :cascade do |t|
    t.string :title
    t.integer :book_id, null: false
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :end_notes, primary_key: :end_note_id, force: :cascade do |t|
    t.string :note
    t.integer :book_id, null: false
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :languages, force: :cascade do |t|
    t.string :name
    t.integer :developer_id
  end

  create_table :shopping_carts, force: :cascade do |t|
    t.string :name, null: true
    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :cart_items, force: :cascade do |t|
    t.string :shopping_cart_id, null: false
    t.string :book_id, null: false
    t.integer :copies, default: 1
    t.datetime :created_at
    t.datetime :updated_at
  end

  add_index :cart_items, [:shopping_cart_id, :book_id], unique: true, name: 'uk_shopping_cart_books'

  create_table :animals, force: :cascade do |t|
    t.string :name, null: false
    t.string :size, default: nil
    t.datetime :created_at
    t.datetime :updated_at
  end

  add_index :animals, [:name], unique: true, name: 'uk_animals'

  create_table :widgets, id: false, force: :cascade do |t|
    t.integer :w_id, primary_key: true
    t.boolean :active, default: false
    t.text :data
    t.text :json_data
    t.text :unspecified_data
    t.text :custom_data
  end

  create_table :promotions, primary_key: :promotion_id, force: :cascade do |t|
    t.string :code
    t.string :description
    t.decimal :discount
  end

  add_index :promotions, [:code], unique: true, name: 'uk_code'

  create_table :discounts, force: :cascade do |t|
    t.decimal :amount
    t.integer :discountable_id
    t.string :discountable_type
  end

  create_table :rules, id: false, force: :cascade do |t|
    t.integer :id
    t.string :condition_text
    t.integer :question_id
  end

  create_table :questions, force: :cascade do |t|
    t.string :body
  end

  create_table :vendors, force: :cascade do |t|
    t.string :name, null: true
    t.text :preferences
    t.text :data
    t.text :config
    t.text :settings
  end

  create_table :cars, id: false, force: :cascade do |t|
    t.string :Name, null: true
    t.string :Features
  end

  create_table :users, force: :cascade do |t|
    t.string :name, null: false
    t.integer :lock_version, null: false, default: 0
  end

  create_table :user_tokens, force: :cascade do |t|
    t.string :user_name, null: false
    t.string :token, null: false
  end

  create_table :accounts, force: :cascade do |t|
    t.string :name, null: false
    t.integer :lock, null: false, default: 0
  end

  create_table :bike_makers, force: :cascade do |t|
    t.string :name, null: false
    t.integer :lock_version, null: false, default: 0
  end

  add_index :cars, :Name, unique: true

  unless ENV["SKIP_COMPOSITE_PK"]
    execute %(
    CREATE TABLE IF NOT EXISTS tags (
          tag_id    INT NOT NULL,
          publisher_id INT NOT NULL,
          tag       VARCHAR(50),
          PRIMARY KEY (tag_id, publisher_id)
      );
    ).split.join(' ').strip

    create_table :tag_aliases, force: :cascade do |t|
      t.integer :tag_id, null: false
      t.integer :parent_id, null: false
      t.string :alias, null: false
    end
  end

  create_table :customers, force: :cascade do |t|
    t.integer :account_id
    t.string :name
  end

  create_table :orders, force: :cascade do |t|
    t.integer :account_id
    t.integer :customer_id
    t.integer :amount
  end
end
