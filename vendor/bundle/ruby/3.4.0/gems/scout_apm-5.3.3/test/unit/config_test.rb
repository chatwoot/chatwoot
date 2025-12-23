require 'test_helper'

require 'scout_apm/config'

class ConfigTest < Minitest::Test
  def setup
    @context = ScoutApm::AgentContext.new
  end

  def test_initalize_without_a_config
    conf = ScoutApm::Config.without_file(@context)

    # nil for random keys
    assert_nil conf.value('log_file_path')

    # but has values for defaulted keys
    assert conf.value('host')

    # and still reads from ENV
    ENV['SCOUT_CONFIG_TEST_KEY'] = 'testval'
    assert_equal 'testval', conf.value('config_test_key')
  end

  def test_loading_a_file
    set_rack_env('production')

    conf_file = File.expand_path('../../data/config_test_1.yml', __FILE__)
    conf = ScoutApm::Config.with_file(@context, conf_file)

    assert_equal 'debug', conf.value('log_level')
    assert_equal 'APM Test Conf (Production)', conf.value('name')
  end

  def test_loading_file_without_env_in_file
    conf_file = File.expand_path("../../data/config_test_1.yml", __FILE__)
    conf = ScoutApm::Config.with_file(@context, conf_file, :environment => "staging")

    assert_equal "info", conf.value('log_level') # the default value
    assert_nil nil, conf.value('name')         # the default value
  end

  def test_boolean_coercion
    coercion = ScoutApm::Config::BooleanCoercion.new
    assert_equal true, coercion.coerce("true")
    assert_equal true, coercion.coerce("t")
    assert_equal false, coercion.coerce("false")
    assert_equal false, coercion.coerce("f")
    assert_equal false, coercion.coerce("")

    assert_equal true, coercion.coerce(true)
    assert_equal false, coercion.coerce(false)
    assert_equal false, coercion.coerce(nil)

    assert_equal true, coercion.coerce(1)
    assert_equal true, coercion.coerce(20)
    assert_equal true, coercion.coerce(-1)
    assert_equal false, coercion.coerce(0)

    # for any other unknown class, there is no clear answer, so be safe and say false.
    assert_equal false, coercion.coerce([])
  end

  def test_json_coersion
    coercion = ScoutApm::Config::JsonCoercion.new
    assert_equal [1,2,3], coercion.coerce('[1,2,3]')
    assert_equal ['foo/bar','baz/quux'], coercion.coerce('["foo/bar", "baz/quux"]')

    assert_equal({"foo" => "bar"}, coercion.coerce('{"foo": "bar"}'))

    assert_equal true, coercion.coerce(true)
    assert_equal 10, coercion.coerce(10)
    assert_equal ["a"], coercion.coerce(["a"])
  end

  def test_any_keys_found
    ENV.stubs(:has_key?).returns(nil)

    conf = ScoutApm::Config.with_file(@context, "a_file_that_doesnt_exist.yml")
    assert ! conf.any_keys_found?

    ENV.stubs(:has_key?).with("SCOUT_MONITOR").returns("true")
    conf = ScoutApm::Config.with_file(@context, "a_file_that_doesnt_exist.yml")
    assert conf.any_keys_found?
  end
end
