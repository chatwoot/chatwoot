require File.expand_path('../spec_helper', __FILE__)
require "pid_behavior"

if ChildProcess.unix?

  describe ChildProcess::Unix::Process do
    it_behaves_like "a platform that provides the child's pid"

    it "handles ECHILD race condition where process dies between timeout and KILL" do
      process = sleeping_ruby

      allow(Process).to receive(:spawn).and_return('fakepid')
      allow(process).to receive(:send_term)
      allow(process).to receive(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
      allow(process).to receive(:send_kill).and_raise(Errno::ECHILD.new)

      process.start
      expect { process.stop }.not_to raise_error

      allow(process).to receive(:alive?).and_return(false)
    end

    it "handles ESRCH race condition where process dies between timeout and KILL" do
      process = sleeping_ruby

      allow(Process).to receive(:spawn).and_return('fakepid')
      allow(process).to receive(:send_term)
      allow(process).to receive(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
      allow(process).to receive(:send_kill).and_raise(Errno::ESRCH.new)

      process.start
      expect { process.stop }.not_to raise_error

      allow(process).to receive(:alive?).and_return(false)
    end
  end

  describe ChildProcess::Unix::IO do
    let(:io) { ChildProcess::Unix::IO.new }

    it "raises an ArgumentError if given IO does not respond to :to_io" do
      expect { io.stdout = nil }.to raise_error(ArgumentError, /to respond to :to_io/)
    end

    it "raises a TypeError if #to_io does not return an IO" do
      fake_io = Object.new
      def fake_io.to_io() StringIO.new end

      expect { io.stdout = fake_io }.to raise_error(TypeError, /expected IO, got/)
    end
  end

end
