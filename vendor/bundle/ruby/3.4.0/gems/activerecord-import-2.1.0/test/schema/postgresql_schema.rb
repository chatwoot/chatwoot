# frozen_string_literal: true

ActiveRecord::Schema.define do
  execute('CREATE extension IF NOT EXISTS "hstore";')
  execute('CREATE extension IF NOT EXISTS "pgcrypto";')
  execute('CREATE extension IF NOT EXISTS "uuid-ossp";')

  # create ENUM if it does not exist yet
  begin
    execute('CREATE TYPE vendor_type AS ENUM (\'wholesaler\', \'retailer\');')
  rescue ActiveRecord::StatementInvalid
    execute('ALTER TYPE vendor_type ADD VALUE IF NOT EXISTS \'wholesaler\';')
    execute('ALTER TYPE vendor_type ADD VALUE IF NOT EXISTS \'retailer\';')
  end

  create_table :vendors, id: :uuid, force: :cascade do |t|
    t.string :name, null: true
    t.text :hours
    t.text :preferences

    if t.respond_to?(:json)
      t.json :pure_json_data
      t.json :data
    else
      t.text :data
    end

    if t.respond_to?(:hstore)
      t.hstore :config
    else
      t.text :config
    end

    if t.respond_to?(:jsonb)
      t.jsonb :pure_jsonb_data
      t.jsonb :settings
      t.jsonb :json_data, null: false, default: {}
    else
      t.text :settings
      t.text :json_data
    end

    t.column :vendor_type, :vendor_type

    t.datetime :created_at
    t.datetime :updated_at
  end

  create_table :alarms, force: true do |t|
    t.column :device_id, :integer, null: false
    t.column :alarm_type, :integer, null: false
    t.column :status, :integer, null: false
    t.column :metadata, :text
    t.column :secret_key, :binary
    t.datetime :created_at
    t.datetime :updated_at
  end

  add_index :alarms, [:device_id, :alarm_type], unique: true, where: 'status <> 0'

  unless ENV["SKIP_COMPOSITE_PK"]
    create_table :authors, force: :cascade do |t|
      t.string :name
    end

    execute %(
      DROP SEQUENCE IF EXISTS composite_book_id_seq CASCADE;
      CREATE SEQUENCE composite_book_id_seq
          AS integer
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      DROP TABLE IF EXISTS composite_books;
      CREATE TABLE composite_books (
          id bigint DEFAULT nextval('composite_book_id_seq'::regclass) NOT NULL,
          title character varying,
          author_id bigint
       );

      ALTER TABLE ONLY composite_books ADD CONSTRAINT fk_rails_040a418131 FOREIGN KEY (author_id) REFERENCES authors(id);
    ).split.join(' ').strip
  end

  create_table :composite_chapters, force: :cascade do |t|
    t.string :title
    t.integer :composite_book_id, null: false
    t.integer :author_id, null: false
    t.datetime :created_at
    t.datetime :updated_at
  end
end
