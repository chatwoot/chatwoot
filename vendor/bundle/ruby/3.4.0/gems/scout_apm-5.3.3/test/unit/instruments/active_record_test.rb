require 'test_helper'
require 'sqlite3'
require 'active_record'

begin
  require 'octoshark'
rescue LoadError
  # Ignore
end

class ActiveRecordTest < Minitest::Test
  def database_path
    File.expand_path('test.sqlite3', DATA_FILE_DIR)
  end

  def setup
    database = SQLite3::Database.new(database_path)
    database.execute("DROP TABLE IF EXISTS users;")
    database.execute("CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100));")

    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => database_path)
  end

  class User < ActiveRecord::Base
  end

  def test_instrumentation
    recorder = FakeRecorder.new
    agent_context.recorder = recorder

    instrument = ScoutApm::Instruments::ActiveRecord.new(agent_context)
    instrument.install(prepend: false)

    ScoutApm::Tracer.instrument("Controller", "foo/bar") do
      user = User.create
    end

    assert 1, recorder.requests.size
  end
end
