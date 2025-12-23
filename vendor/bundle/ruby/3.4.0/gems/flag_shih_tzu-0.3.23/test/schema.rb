ActiveRecord::Schema.define(:version => 0) do
  create_table :spaceships, :force => true do |t|
    t.integer :flags, :null => false, :default => 0
    t.string :incorrect_flags_column, :null => false, :default => ''
  end

  create_table :spaceships_with_custom_flags_column, :force => true do |t|
    t.integer :bits, :null => false, :default => 0
  end

  create_table :spaceships_with_2_custom_flags_column, :force => true do |t|
    t.integer :bits, :null => false, :default => 0
    t.integer :commanders, :null => false, :default => 0
  end

  create_table :spaceships_with_3_custom_flags_column, :force => true do |t|
    t.integer :engines, :null => false, :default => 0
    t.integer :weapons, :null => false, :default => 0
    t.integer :hal3000, :null => false, :default => 0
  end

  create_table :spaceships_with_3_custom_flags_column, :force => true do |t|
    t.integer :engines, :null => false, :default => 0
    t.integer :weapons, :null => false, :default => 0
    t.integer :hal3000, :null => false, :default => 0
  end

  create_table :spaceships_with_symbol_and_string_flag_columns, :force => true do |t|
    t.integer :peace, :null => false, :default => 0
    t.integer :love, :null => false, :default => 0
    t.integer :happiness, :null => false, :default => 0
  end

  create_table :spaceships_without_flags_column, :force => true do |t|
  end

  create_table :spaceships_with_non_integer_column, :force => true do |t|
    t.string :flags, :null => false, :default => 'A string'
  end
end
