# Mock Rails.application.eager_load! and define some
# Rails models for use in specs.
class Rails
  def self.application
    self
  end

  def self.eager_load!
    @already_called ||= false

    if !@already_called
      Object.const_set('Sample', Class.new(ActiveRecord::Base))

      Object.const_set('AnotherSample', Class.new(ActiveRecord::Base))

      Object.const_set('YetAnotherSample', Class.new(ActiveRecord::Base))

      Object.const_set('NoTableModel', Class.new(ActiveRecord::Base))

      Object.const_set('EmptyModel', Class.new(ActiveRecord::Base))

      @already_called = true
    end
  end

  def self.env
    'test'
  end
end

module Helpers
  def create_db
    ActiveRecord::Migration.verbose = false

    ActiveRecord::Schema.define(:version => 1) do
      create_table 'samples', :force => true do |t|
        t.string   'string'
        t.text     'text'
        t.integer  'integer'
        t.float    'float'
        t.decimal  'decimal'
        t.datetime 'datetime'
        t.time     'time'
        t.date     'date'
        t.binary   'binary'
        t.boolean  'boolean'
        t.datetime 'created_at', :null => false
        t.datetime 'updated_at', :null => false
      end

      create_table 'another_samples', :force => true do |t|
        t.string   'string'
        t.text     'text'
        t.integer  'integer'
        t.float    'float'
        t.decimal  'decimal'
        t.datetime 'datetime'
        t.time     'time'
        t.date     'date'
        t.binary   'binary'
        t.boolean  'boolean'
        t.datetime 'created_at', :null => false
        t.datetime 'updated_at', :null => false
      end

      create_table 'yet_another_samples', :force => true do |t|
        t.string   'string'
        t.text     'text'
        t.integer  'integer'
        t.float    'float'
        t.decimal  'decimal'
        t.datetime 'datetime'
        t.time     'time'
        t.date     'date'
        t.binary   'binary'
        t.boolean  'boolean'
        t.datetime 'created_at', :null => false
        t.datetime 'updated_at', :null => false
      end

      create_table 'empty_models', force: true
    end
  end

  def load_sample_data
    Rails.application.eager_load!

    Sample.create!

    ChildSample.create!
  end
end
