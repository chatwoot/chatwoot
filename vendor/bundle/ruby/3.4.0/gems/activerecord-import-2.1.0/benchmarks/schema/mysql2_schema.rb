# frozen_string_literal: true

ActiveRecord::Schema.define do
  create_table :test_myisam, options: 'ENGINE=MyISAM', force: true do |t|
    t.column :my_name, :string, null: false
    t.column :description, :string
  end

  create_table :test_innodb, options: 'ENGINE=InnoDb', force: true do |t|
    t.column :my_name, :string, null: false
    t.column :description, :string
  end

  create_table :test_memory, options: 'ENGINE=Memory', force: true do |t|
    t.column :my_name, :string, null: false
    t.column :description, :string
  end
end
