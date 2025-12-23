$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'stackprof/middleware'
require 'minitest/autorun'
require 'mocha/setup'

class StackProf::MiddlewareTest < MiniTest::Test

  def test_path_default
    StackProf::Middleware.new(Object.new)

    assert_equal 'tmp/', StackProf::Middleware.path
  end

  def test_path_custom
    StackProf::Middleware.new(Object.new, { path: 'foo/' })

    assert_equal 'foo/', StackProf::Middleware.path
  end

  def test_save_default
    StackProf::Middleware.new(Object.new)

    StackProf.stubs(:results).returns({ mode: 'foo' })
    FileUtils.expects(:mkdir_p).with('tmp/')
    File.expects(:open).with(regexp_matches(/^tmp\/stackprof-foo/), 'wb')

    StackProf::Middleware.save
  end

  def test_save_custom
    StackProf::Middleware.new(Object.new, { path: 'foo/' })

    StackProf.stubs(:results).returns({ mode: 'foo' })
    FileUtils.expects(:mkdir_p).with('foo/')
    File.expects(:open).with(regexp_matches(/^foo\/stackprof-foo/), 'wb')

    StackProf::Middleware.save
  end

  def test_enabled_should_use_a_proc_if_passed
    env = {}

    StackProf::Middleware.new(Object.new, enabled: Proc.new{ false })
    refute StackProf::Middleware.enabled?(env)

    StackProf::Middleware.new(Object.new, enabled: Proc.new{ true })
    assert StackProf::Middleware.enabled?(env)
  end

  def test_enabled_should_use_a_proc_if_passed_and_use_the_request_env
    enable_proc = Proc.new {|env| env['PROFILE'] }

    env = Hash.new { false }
    StackProf::Middleware.new(Object.new, enabled: enable_proc)
    refute StackProf::Middleware.enabled?(env)

    env = Hash.new { true }
    StackProf::Middleware.new(Object.new, enabled: enable_proc)
    assert StackProf::Middleware.enabled?(env)
  end

  def test_raw
    StackProf::Middleware.new(Object.new, raw: true)
    assert StackProf::Middleware.raw
  end

  def test_metadata
    metadata = { key: 'value' }
    StackProf::Middleware.new(Object.new, metadata: metadata)
    assert_equal metadata, StackProf::Middleware.metadata
  end
end
