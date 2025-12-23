require "spec_helper"
require "foreman/engine"

class Foreman::Engine::Tester < Foreman::Engine
  attr_reader :buffer

  def startup
    @buffer = ""
  end

  def output(name, data)
    @buffer += "#{name}: #{data}"
  end

  def shutdown
  end
end

describe "Foreman::Engine", :fakefs do
  subject do
    write_procfile "Procfile"
    Foreman::Engine::Tester.new.load_procfile("Procfile")
  end

  describe "initialize" do
    describe "with a Procfile" do
      before { write_procfile }

      it "reads the processes" do
        expect(subject.process("alpha").command).to eq("./alpha")
        expect(subject.process("bravo").command).to eq("./bravo")
      end
    end
  end

  describe "start" do
    it "forks the processes" do
      expect(subject.process("alpha")).to receive(:run)
      expect(subject.process("bravo")).to receive(:run)
      expect(subject).to receive(:watch_for_output)
      expect(subject).to receive(:wait_for_shutdown_or_child_termination)
      subject.start
    end

    it "handles concurrency" do
      subject.options[:formation] = "alpha=2"
      expect(subject.process("alpha")).to receive(:run).twice
      expect(subject.process("bravo")).to_not receive(:run)
      expect(subject).to receive(:watch_for_output)
      expect(subject).to receive(:wait_for_shutdown_or_child_termination)
      subject.start
    end
  end

  describe "directories" do
    it "has the directory default relative to the Procfile" do
      write_procfile "/some/app/Procfile"
      engine = Foreman::Engine.new.load_procfile("/some/app/Procfile")
      expect(engine.root).to eq("/some/app")
    end
  end

  describe "environment" do
    it "should read env files" do
      write_file("/tmp/env") { |f| f.puts("FOO=baz") }
      subject.load_env("/tmp/env")
      expect(subject.env["FOO"]).to eq("baz")
    end

    it "should read more than one if specified" do
      write_file("/tmp/env1") { |f| f.puts("FOO=bar") }
      write_file("/tmp/env2") { |f| f.puts("BAZ=qux") }
      subject.load_env "/tmp/env1"
      subject.load_env "/tmp/env2"
      expect(subject.env["FOO"]).to eq("bar")
      expect(subject.env["BAZ"]).to eq("qux")
    end

    it "should handle quoted values" do
      write_file("/tmp/env") do |f|
        f.puts 'FOO=bar'
        f.puts 'BAZ="qux"'
        f.puts "FRED='barney'"
        f.puts 'OTHER="escaped\"quote"'
        f.puts 'URL="http://example.com/api?foo=bar&baz=1"'
      end
      subject.load_env "/tmp/env"
      expect(subject.env["FOO"]).to   eq("bar")
      expect(subject.env["BAZ"]).to   eq("qux")
      expect(subject.env["FRED"]).to  eq("barney")
      expect(subject.env["OTHER"]).to eq('escaped"quote')
      expect(subject.env["URL"]).to   eq("http://example.com/api?foo=bar&baz=1")
    end

    it "should handle multiline strings" do
      write_file("/tmp/env") do |f|
        f.puts 'FOO="bar\nbaz"'
      end
      subject.load_env "/tmp/env"
      expect(subject.env["FOO"]).to eq("bar\nbaz")
    end

    it "should fail if specified and doesnt exist" do
      expect { subject.load_env "/tmp/env" }.to raise_error(Errno::ENOENT)
    end

    it "should set port from .env if specified" do
      write_file("/tmp/env") { |f| f.puts("PORT=9000") }
      subject.load_env "/tmp/env"
      expect(subject.send(:base_port)).to eq(9000)
    end
  end

end
