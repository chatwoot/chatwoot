require 'spec_helper'
require 'tmpdir'
require 'concurrent'

describe INotify::Notifier do
  describe "instance" do
    around do |block|
      Dir.mktmpdir do |dir|
        @root = Pathname.new(dir)
        @notifier = INotify::Notifier.new

        begin
          block.call
        ensure
          @notifier.close
        end
      end
    end

    let(:dir) do
      @root.join("foo").tap(&:mkdir)
    end

    let(:another_dir) do
      @root.join("bar").tap(&:mkdir)
    end

    it "stops" do
      @notifier.stop
    end

    describe :process do
      it "gets events" do
        events = recording(dir, :create)
        dir.join("test.txt").write("hello world")

        @notifier.process

        expect(events.size).to eq(1)
        expect(events.first.name).to eq("test.txt")
        expect(events.first.absolute_name).to eq(dir.join("test.txt").to_s)
      end

      it "gets simultaneous events" do
        events = recording(dir, :create)

        dir.join("one.txt").write("hello world")
        dir.join("two.txt").write("hello world")

        @notifier.process

        expect(events.map(&:name)).to match_array(%w(one.txt two.txt))
      end

      it "separates events between watches" do
        bar_events = nil

        foo_events = recording(dir, :create)
        bar_events = recording(another_dir, :create)

        dir.join("test.txt").write("hello world")
        another_dir.join("test_two.txt").write("hello world")

        @notifier.process

        expect(foo_events.size).to eq(1)
        expect(foo_events.first.name).to eq("test.txt")
        expect(foo_events.first.absolute_name).to eq(dir.join("test.txt").to_s)

        expect(bar_events.size).to eq(1)
        expect(bar_events.first.name).to eq("test_two.txt")
        expect(bar_events.first.absolute_name).to eq(another_dir.join("test_two.txt").to_s)
      end
    end

    describe :run do
      it "processes repeatedly until stopped" do
        barriers = Array.new(3) { Concurrent::Event.new }
        barrier_queue = barriers.dup
        events = recording(dir, :create) { barrier_queue.shift.set }

        run_thread = Thread.new { @notifier.run }

        dir.join("one.txt").write("hello world")
        barriers.shift.wait(1) or raise "timeout"

        expect(events.map(&:name)).to match_array(%w(one.txt))

        dir.join("two.txt").write("hello world")
        barriers.shift.wait(1) or raise "timeout"

        expect(events.map(&:name)).to match_array(%w(one.txt two.txt))

        @notifier.stop

        dir.join("three.txt").write("hello world")
        barriers.shift.wait(1)

        dir.join("four.txt").write("hello world")
        run_thread.join

        expect(events.map(&:name)).to match_array(%w(one.txt two.txt))
      end

      it "can be stopped from within a callback" do
        barriers = Array.new(3) { Concurrent::Event.new }
        barrier_queue = barriers.dup
        events = recording(dir, :create) { @notifier.stop }

        run_thread = Thread.new { @notifier.run }
        dir.join("one.txt").write("hello world")
        run_thread.join
      end
    end

    describe :fd do
      it "returns an integer" do
        expect(@notifier.fd).to be_an(Integer)
      end
    end

    describe :to_io do
      it "returns a ruby IO" do
        expect(@notifier.to_io).to be_an(::IO)
      end

      it "matches the fd" do
        expect(@notifier.to_io.fileno).to eq(@notifier.fd)
      end

      it "caches its result" do
        expect(@notifier.to_io).to be(@notifier.to_io)
      end

      it "is selectable" do
        events = recording(dir, :create)
        expect(select([@notifier.to_io], nil, nil, 0.2)).to be_nil

        dir.join("test.txt").write("hello world")
        expect(select([@notifier.to_io], nil, nil, 0.2)).to eq([[@notifier.to_io], [], []])

        @notifier.process
        expect(select([@notifier.to_io], nil, nil, 0.2)).to be_nil
      end
    end

    private

    def recording(dir, *flags, callback: nil)
      events = []
      @notifier.watch(dir.to_s, *flags) do |event|
        events << event
        yield if block_given?
      end

      events
    end
  end

  describe "mixed instances" do
    it "doesn't tangle fds" do
      notifiers = Array.new(30) { INotify::Notifier.new }
      notifiers.each(&:to_io)

      one = Array.new(10) { IO.pipe.last }
      notifiers.each(&:close)

      two = Array.new(10) { IO.pipe.last }

      notifiers = nil
      GC.start

      _, writable, _ = select(nil, one, nil, 1)
      expect(writable).to match_array(one)

      _, writable, _ = select(nil, two, nil, 1)
      expect(writable).to match_array(two)
    end
  end
end
