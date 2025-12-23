$:.unshift File.expand_path('../../lib', __FILE__)
require 'stackprof'
require 'minitest/autorun'
require 'tempfile'
require 'pathname'

class StackProfTest < MiniTest::Test
  def setup
    Object.new # warm some caches to avoid flakiness
  end

  def test_info
    profile = StackProf.run{}
    assert_equal 1.2, profile[:version]
    assert_equal :wall, profile[:mode]
    assert_equal 1000, profile[:interval]
    assert_equal 0, profile[:samples]
  end

  def test_running
    assert_equal false, StackProf.running?
    StackProf.run{ assert_equal true, StackProf.running? }
  end

  def test_start_stop_results
    assert_nil StackProf.results
    assert_equal true, StackProf.start
    assert_equal false, StackProf.start
    assert_equal true, StackProf.running?
    assert_nil StackProf.results
    assert_equal true, StackProf.stop
    assert_equal false, StackProf.stop
    assert_equal false, StackProf.running?
    assert_kind_of Hash, StackProf.results
    assert_nil StackProf.results
  end

  def test_object_allocation
    profile_base_line = __LINE__+1
    profile = StackProf.run(mode: :object) do
      Object.new
      Object.new
    end
    assert_equal :object, profile[:mode]
    assert_equal 1, profile[:interval]
    if RUBY_VERSION >= '3'
      assert_equal 4, profile[:samples]
    else
      assert_equal 2, profile[:samples]
    end

    frame = profile[:frames].values.first
    assert_includes frame[:name], "StackProfTest#test_object_allocation"
    assert_equal 2, frame[:samples]
    assert_includes [profile_base_line - 2, profile_base_line], frame[:line]
    if RUBY_VERSION >= '3'
      assert_equal [2, 1], frame[:lines][profile_base_line+1]
      assert_equal [2, 1], frame[:lines][profile_base_line+2]
    else
      assert_equal [1, 1], frame[:lines][profile_base_line+1]
      assert_equal [1, 1], frame[:lines][profile_base_line+2]
    end
    frame = profile[:frames].values[1] if RUBY_VERSION < '2.3'

    if RUBY_VERSION >= '3'
      assert_equal [4, 0], frame[:lines][profile_base_line]
    else
      assert_equal [2, 0], frame[:lines][profile_base_line]
    end
  end

  def test_object_allocation_interval
    profile = StackProf.run(mode: :object, interval: 10) do
      100.times { Object.new }
    end
    assert_equal 10, profile[:samples]
  end

  def test_cputime
    profile = StackProf.run(mode: :cpu, interval: 500) do
      math
    end

    assert_operator profile[:samples], :>=, 1
    if RUBY_VERSION >= '3'
      assert profile[:frames].values.take(2).map { |f|
        f[:name].include? "StackProfTest#math"
      }.any?
    else
      frame = profile[:frames].values.first
      assert_includes frame[:name], "StackProfTest#math"
    end
  end

  def test_walltime
    profile = StackProf.run(mode: :wall) do
      idle
    end

    frame = profile[:frames].values.first
    if RUBY_VERSION >= '3'
      assert_equal "IO.select", frame[:name]
    else
      assert_equal "StackProfTest#idle", frame[:name]
    end
    assert_in_delta 200, frame[:samples], 25
  end

  def test_custom
    profile_base_line = __LINE__+1
    profile = StackProf.run(mode: :custom) do
      10.times do
        StackProf.sample
      end
    end

    assert_equal :custom, profile[:mode]
    assert_equal 10, profile[:samples]

    offset = RUBY_VERSION >= '3' ? 1 : 0
    frame = profile[:frames].values[offset]
    assert_includes frame[:name], "StackProfTest#test_custom"
    assert_includes [profile_base_line-2, profile_base_line+1], frame[:line]

    if RUBY_VERSION >= '3'
      assert_equal [10, 0], frame[:lines][profile_base_line+2]
    else
      assert_equal [10, 10], frame[:lines][profile_base_line+2]
    end
  end

  def test_raw
    before_monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)

    profile = StackProf.run(mode: :custom, raw: true) do
      10.times do
        StackProf.sample
        sleep 0.0001
      end
    end

    after_monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)

    raw = profile[:raw]
    assert_equal 10, raw[-1]
    assert_equal raw[0] + 2, raw.size

    offset = RUBY_VERSION >= '3' ? -3 : -2
    assert_includes profile[:frames][raw[offset]][:name], 'StackProfTest#test_raw'

    assert_equal 10, profile[:raw_sample_timestamps].size
    profile[:raw_sample_timestamps].each_cons(2) do |t1, t2|
      assert_operator t1, :>, before_monotonic
      assert_operator t2, :>=, t1
      assert_operator t2, :<, after_monotonic
    end

    assert_equal 10, profile[:raw_timestamp_deltas].size
    total_duration = after_monotonic - before_monotonic
    assert_operator profile[:raw_timestamp_deltas].inject(&:+), :<, total_duration

    profile[:raw_timestamp_deltas].each do |delta|
      assert_operator delta, :>, 0
    end
  end

  def test_metadata
    metadata = {
      path: '/foo/bar',
      revision: '5c0b01f1522ae8c194510977ae29377296dd236b',
    }
    profile = StackProf.run(mode: :cpu, metadata: metadata) do
      math
    end

    assert_equal metadata, profile[:metadata]
  end

  def test_empty_metadata
    profile = StackProf.run(mode: :cpu) do
      math
    end

    assert_equal({}, profile[:metadata])
  end

  def test_raises_if_metadata_is_not_a_hash
    exception = assert_raises ArgumentError do
      StackProf.run(mode: :cpu, metadata: 'foobar') do
        math
      end
    end

    assert_equal 'metadata should be a hash', exception.message
  end

  def test_fork
    StackProf.run do
      pid = fork do
        exit! StackProf.running?? 1 : 0
      end
      Process.wait(pid)
      assert_equal 0, $?.exitstatus
      assert_equal true, StackProf.running?
    end
  end

  def foo(n = 10)
    if n == 0
      StackProf.sample
      return
    end
    foo(n - 1)
  end

  def test_recursive_total_samples
    profile = StackProf.run(mode: :cpu, raw: true) do
      10.times do
        foo
      end
    end

    frame = profile[:frames].values.find do |frame|
      frame[:name] == "StackProfTest#foo"
    end
    assert_equal 10, frame[:total_samples]
  end

  def test_gc
    profile = StackProf.run(interval: 100, raw: true) do
      5.times do
        GC.start
      end
    end

    gc_frame = profile[:frames].values.find{ |f| f[:name] == "(garbage collection)" }
    marking_frame = profile[:frames].values.find{ |f| f[:name] == "(marking)" }
    sweeping_frame = profile[:frames].values.find{ |f| f[:name] == "(sweeping)" }

    assert gc_frame
    assert marking_frame
    assert sweeping_frame

    assert_equal gc_frame[:total_samples], profile[:gc_samples]
    assert_equal profile[:gc_samples], [gc_frame, marking_frame, sweeping_frame].map{|x| x[:samples] }.inject(:+)

    assert_operator profile[:gc_samples], :>, 0
    assert_operator profile[:missed_samples], :<=, 25
  end

  def test_out
    tmpfile = Tempfile.new('stackprof-out')
    ret = StackProf.run(mode: :custom, out: tmpfile) do
      StackProf.sample
    end

    assert_equal tmpfile, ret
    tmpfile.rewind
    profile = Marshal.load(tmpfile.read)
    refute_empty profile[:frames]
  end

  def test_out_to_path_string
    tmpfile = Tempfile.new('stackprof-out')
    ret = StackProf.run(mode: :custom, out: tmpfile.path) do
      StackProf.sample
    end

    refute_equal tmpfile, ret
    assert_equal tmpfile.path, ret.path
    tmpfile.rewind
    profile = Marshal.load(tmpfile.read)
    refute_empty profile[:frames]
  end

  def test_pathname_out
    tmpfile  = Tempfile.new('stackprof-out')
    pathname = Pathname.new(tmpfile.path)
    ret = StackProf.run(mode: :custom, out: pathname) do
      StackProf.sample
    end

    assert_equal tmpfile.path, ret.path
    tmpfile.rewind
    profile = Marshal.load(tmpfile.read)
    refute_empty profile[:frames]
  end

  def test_min_max_interval
    [-1, 0, 1_000_000, 1_000_001].each do |invalid_interval|
      err = assert_raises(ArgumentError, "invalid interval #{invalid_interval}") do
        StackProf.run(interval: invalid_interval, debug: true) {}
      end
      assert_match(/microseconds/, err.message)
    end
  end

  def math
    250_000.times do
      2 ** 10
    end
  end

  def idle
    r, w = IO.pipe
    IO.select([r], nil, nil, 0.2)
  ensure
    r.close
    w.close
  end
end unless RUBY_ENGINE == 'truffleruby'
