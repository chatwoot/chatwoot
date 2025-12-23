require File.expand_path('../spec_helper', __FILE__)
require "pid_behavior"

if ChildProcess.windows?
  describe ChildProcess::Windows::Process do
    it_behaves_like "a platform that provides the child's pid"
  end

  describe ChildProcess::Windows::IO do
    let(:io) { ChildProcess::Windows::IO.new }

    it "raises an ArgumentError if given IO does not respond to :fileno" do
      expect { io.stdout = nil }.to raise_error(ArgumentError, /must have :fileno or :to_io/)
    end

    it "raises an ArgumentError if the #to_io does not return an IO " do
      fake_io = Object.new
      def fake_io.to_io() StringIO.new end

      expect { io.stdout = fake_io }.to raise_error(ArgumentError, /must have :fileno or :to_io/)
    end
  end
end
