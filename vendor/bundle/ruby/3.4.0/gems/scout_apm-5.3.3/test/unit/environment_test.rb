require 'test_helper'

require 'scout_apm/environment'

class EnvironmentTest < Minitest::Test
  def teardown
    clean_fake_rails
    clean_fake_sinatra
  end

  def test_framework_rails
    fake_rails(2)
    assert_equal :rails, ScoutApm::Environment.send(:new).framework

    clean_fake_rails
    fake_rails(3)
    assert_equal :rails3_or_4, ScoutApm::Environment.send(:new).framework

    clean_fake_rails
    fake_rails(4)
    assert_equal :rails3_or_4, ScoutApm::Environment.send(:new).framework
  end

  def test_framework_sinatra
    fake_sinatra
    assert_equal :sinatra, ScoutApm::Environment.send(:new).framework
  end

  def test_framework_ruby
    assert_equal :ruby, ScoutApm::Environment.send(:new).framework
  end

  ############################################################

  def fake_rails(version)
    Kernel.const_set("Rails", Module.new)
    Kernel.const_set("ActionController", Module.new)
    r = Kernel.const_get("Rails")
    r.const_set("VERSION", Module.new)
    v = r.const_get("VERSION")
    v.const_set("MAJOR", version)

    assert_equal version, Rails::VERSION::MAJOR
  end

  def clean_fake_rails
    Kernel.send(:remove_const, "Rails") if defined?(Kernel::Rails)
    Kernel.send(:remove_const, "ActionController") if defined?(Kernel::ActionController)
  end

  def fake_sinatra
    Kernel.const_set("Sinatra", Module.new)
    s = Kernel.const_get("Sinatra")
    s.const_set("Base", Module.new)
  end

  def clean_fake_sinatra
    Kernel.const_unset("Sinatra") if defined?(Kernel::Sinatra)
  end
end
