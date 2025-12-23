require 'seed_dump'

require 'active_support'
require 'active_record'

require 'tempfile'

require 'byebug'

require 'database_cleaner'
require 'factory_bot'

require './spec/helpers'

ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

FactoryBot.find_definitions

RSpec.configure do |config|
  config.order = 'random'

  config.include Helpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
