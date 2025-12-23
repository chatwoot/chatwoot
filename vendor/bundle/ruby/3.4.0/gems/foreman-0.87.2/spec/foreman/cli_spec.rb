require "spec_helper"
require "foreman/cli"

describe "Foreman::CLI", :fakefs do
  subject { Foreman::CLI.new }

  describe ".foreman" do
    before { File.open(".foreman", "w") { |f| f.puts "formation: alpha=2" } }

    it "provides default options" do
      expect(subject.send(:options)["formation"]).to eq("alpha=2")
    end

    it "is overridden by options at the cli" do
      subject = Foreman::CLI.new([], :formation => "alpha=3")
      expect(subject.send(:options)["formation"]).to eq("alpha=3")
    end
  end

  describe "start" do
    describe "when a Procfile doesnt exist", :fakefs do
      it "displays an error" do
        mock_error(subject, "Procfile does not exist.") do
          expect_any_instance_of(Foreman::Engine).to_not receive(:start)
          subject.start
        end
      end
    end

    describe "with a valid Procfile" do
      it "can run a single command" do
        without_fakefs do
          output = foreman("start env -f #{resource_path("Procfile")}")
          expect(output).to     match(/env.1/)
          expect(output).not_to match(/test.1/)
        end
      end

      it "can run all commands" do
        without_fakefs do
          output = foreman("start -f #{resource_path("Procfile")} -e #{resource_path(".env")}")
          expect(output).to match(/echo.1 \| echoing/)
          expect(output).to match(/env.1  \| bar/)
          expect(output).to match(/test.1 \| testing/)
        end
      end

      it "sets PS variable with the process name" do
        without_fakefs do
          output = foreman("start -f #{resource_path("Procfile")}")
          expect(output).to match(/ps.1   \| PS env var is ps.1/)
        end
      end

      it "fails if process fails" do
        output = `bundle exec foreman start -f #{resource_path "Procfile.bad"} && echo success`
        expect(output).not_to include 'success'
      end
    end
  end

  describe "check" do
    it "with a valid Procfile displays the jobs" do
      write_procfile
      expect(foreman("check")).to eq("valid procfile detected (alpha, bravo, foo_bar, foo-bar)\n")
    end

    it "with a blank Procfile displays an error" do
      FileUtils.touch "Procfile"
      expect(foreman("check")).to eq("ERROR: no processes defined\n")
    end

    it "without a Procfile displays an error" do
      expect(foreman("check")).to eq("ERROR: Procfile does not exist.\n")
    end
  end

  describe "run" do
    it "can run a command" do
      expect(forked_foreman("run echo 1")).to eq("1\n")
    end

    it "doesn't parse options for the command" do
      expect(forked_foreman("run grep -e FOO #{resource_path(".env")}")).to eq("FOO=bar\n")
    end

    it "includes the environment" do
      expect(forked_foreman("run -e #{resource_path(".env")} #{resource_path("bin/env FOO")}")).to eq("bar\n")
    end

    it "can run a command from the Procfile" do
      expect(forked_foreman("run -f #{resource_path("Procfile")} test")).to eq("testing\n")
    end

    it "exits with the same exit code as the command" do
      expect(fork_and_get_exitstatus("run echo 1")).to eq(0)
      expect(fork_and_get_exitstatus("run date 'invalid_date'")).to eq(1)
    end
  end

  describe "version" do
    it "displays gem version" do
      expect(foreman("version").chomp).to eq(Foreman::VERSION)
    end

    it "displays gem version on shortcut command" do
      expect(foreman("-v").chomp).to eq(Foreman::VERSION)
    end
  end

end
