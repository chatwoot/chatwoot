require "helper"
require "spring/watcher/listen"

class ListenWatcherTest < Spring::Test::WatcherTest
  def watcher_class
    Spring::Watcher::Listen
  end

  # this test, as currently written, can only run against polling implementations
  undef :test_add_directory_with_dangling_symlink

  setup do
    Celluloid.boot if defined?(Celluloid)
  end

  teardown { Listen.stop }

  test "root directories" do
    begin
      other_dir_1 = File.realpath(Dir.mktmpdir)
      other_dir_2 = File.realpath(Dir.mktmpdir)
      File.write("#{other_dir_1}/foo", "foo")
      File.write("#{dir}/foo", "foo")

      watcher.add "#{other_dir_1}/foo"
      watcher.add other_dir_2
      watcher.add "#{dir}/foo"

      dirs = [dir, other_dir_1, other_dir_2].sort.map { |path| Pathname.new(path) }
      assert_equal dirs, watcher.base_directories.sort
    ensure
      FileUtils.rm_rf other_dir_1
      FileUtils.rm_rf other_dir_2
    end
  end

  test "root directories with a root subpath directory" do
    begin
      other_dir_1 = "#{dir}_other"
      other_dir_2 = "#{dir}_core"
      # same subpath as dir but with _other or _core appended
      FileUtils::mkdir_p(other_dir_1)
      FileUtils::mkdir_p(other_dir_2)
      File.write("#{other_dir_1}/foo", "foo")
      File.write("#{other_dir_2}/foo", "foo")
      File.write("#{dir}/foo", "foo")

      watcher.add "#{other_dir_1}/foo"
      watcher.add other_dir_2

      dirs = [dir, other_dir_1, other_dir_2].sort.map { |path| Pathname.new(path) }
      assert_equal dirs, watcher.base_directories.sort
    ensure
      FileUtils.rm_rf other_dir_1
      FileUtils.rm_rf other_dir_2
    end
  end

  test "stops listening when already stale" do
    # Track when we're marked as stale.
    on_stale_count = 0
    watcher.on_stale { on_stale_count += 1 }

    # Add a file to watch and start listening.
    file = "#{@dir}/omg"
    touch file, Time.now - 2.seconds
    watcher.add file
    watcher.start
    assert watcher.running?

    # Touch bumps mtime and marks as stale which stops listener.
    touch file, Time.now - 1.second
    Timeout.timeout(1) { sleep 0.1 while watcher.running? }
    assert_equal 1, on_stale_count
  end
end
