require 'test_helper'

require 'scout_apm/auto_instrument'

class AutoInstrumentTest < Minitest::Test
  ROOT = File.expand_path("../../", __dir__)
  
  def source_path(name)
    File.expand_path("auto_instrument/#{name}.rb", __dir__)
  end

  def instrumented_path(name)
    File.expand_path("auto_instrument/#{name}-instrumented.rb", __dir__)
  end

  def instrumented_source(name)
    File.read(instrumented_path(name))
  end

  # Autoinstruments adds a backtrace to each created layer. This is the full path to the
  # test controller.rb file, which will be different on different environments.
  # This normalizes backtraces across environments.
  def normalize_backtrace(string)
    string.gsub(ROOT, "ROOT")
  end

  # Use this to automatically update the test fixtures.
  def update_instrumented_source(name)
    source = ::ScoutApm::AutoInstrument::Rails.rewrite(source_path(name))
    source = normalize_backtrace(source)
    File.write(instrumented_path(name),source)
  end

  def test_controller_rewrite
    # update_instrumented_source("controller")

    assert_equal instrumented_source("controller"),
      normalize_backtrace(::ScoutApm::AutoInstrument::Rails.rewrite(source_path("controller")))
  end

  def test_rescue_from_rewrite
    # update_instrumented_source("rescue_from")

    assert_equal instrumented_source("rescue_from"),
      normalize_backtrace(::ScoutApm::AutoInstrument::Rails.rewrite(source_path("rescue_from")))
  end

  def test_assignments_rewrite
    # update_instrumented_source("assignments")

    assert_equal instrumented_source("assignments"),
      normalize_backtrace(::ScoutApm::AutoInstrument::Rails.rewrite(source_path("assignments")))
  end

  def test_hanging_method_rewrite
    ::ScoutApm::AutoInstrument::Rails.rewrite(source_path("hanging_method"))
  end

  def test_anonymous_block_value
    ::ScoutApm::AutoInstrument::Rails.rewrite(source_path("anonymous_block_value"))
  end
end if defined? ScoutApm::AutoInstrument
