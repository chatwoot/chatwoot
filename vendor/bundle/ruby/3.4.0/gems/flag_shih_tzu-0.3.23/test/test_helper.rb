require "active_record"
require "test/unit"
require "yaml"
require "logger"

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Migration.verbose = false

configs = YAML.load_file(File.dirname(__FILE__) + "/database.yml")
if RUBY_PLATFORM == "java"
  configs["sqlite"]["adapter"] = "jdbcsqlite3"
  configs["mysql"]["adapter"] = "jdbcmysql"
  configs["postgresql"]["adapter"] = "jdbcpostgresql"
end
ActiveRecord::Base.configurations = configs

# Run specific adapter tests like:
#
#   DB=sqlite rake test:all
#   DB=mysql rake test:all
#   DB=postgresql rake test:all
#
db_name = (ENV["DB"] || "sqlite").to_sym
ActiveRecord::Base.establish_connection(db_name)

load(File.dirname(__FILE__) + "/schema.rb")

class Test::Unit::TestCase

  def assert_array_similarity(expected, actual, message=nil)
    full_message = build_message(message, "<?> expected but was\n<?>.\n", expected, actual)
    assert_block(full_message) { (expected.size ==  actual.size) && (expected - actual == []) }
  end

end

# For code coverage, must be required before all application / gem / library code.
begin
  unless ENV["NOCOVER"]
    require "coveralls"
    Coveralls.wear!
  end
rescue LoadError
  # Some builds do not support coveralls
end

require "flag_shih_tzu"
