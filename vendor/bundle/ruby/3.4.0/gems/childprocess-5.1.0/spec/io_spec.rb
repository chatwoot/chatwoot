require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess do
  it "can run even when $stdout is a StringIO" do
    begin
      stdout = $stdout
      $stdout = StringIO.new
      expect { sleeping_ruby.start }.to_not raise_error
    ensure
      $stdout = stdout
    end
  end

  it "can redirect stdout, stderr" do
    process = ruby(<<-CODE)
      [STDOUT, STDERR].each_with_index do |io, idx|
        io.sync = true
        io.puts idx
      end
    CODE

    out = Tempfile.new("stdout-spec")
    err = Tempfile.new("stderr-spec")

    begin
      process.io.stdout = out
      process.io.stderr = err

      process.start
      expect(process.io.stdin).to be_nil
      process.wait

      expect(rewind_and_read(out)).to eq "0\n"
      expect(rewind_and_read(err)).to eq "1\n"
    ensure
      out.close
      err.close
    end
  end

  it "can redirect stdout only" do
    process = ruby(<<-CODE)
      [STDOUT, STDERR].each_with_index do |io, idx|
        io.sync = true
        io.puts idx
      end
    CODE

    out = Tempfile.new("stdout-spec")

    begin
      process.io.stdout = out

      process.start
      process.wait

      expect(rewind_and_read(out)).to eq "0\n"
    ensure
      out.close
    end
  end

  it "pumps all output" do
    process = echo

    out = Tempfile.new("pump")

    begin
      process.io.stdout = out

      process.start
      process.wait

      expect(rewind_and_read(out)).to eq "hello\n"
    ensure
      out.close
    end
  end

  it "can write to stdin if duplex = true" do
    process = cat

    out = Tempfile.new("duplex")
    out.sync = true

    begin
      process.io.stdout = out
      process.io.stderr = out
      process.duplex = true

      process.start
      process.io.stdin.puts "hello world"
      process.io.stdin.close

      process.poll_for_exit(exit_timeout)

      expect(rewind_and_read(out)).to eq "hello world\n"
    ensure
      out.close
    end
  end

  it "can write to stdin interactively if duplex = true" do
    process = cat

    out = Tempfile.new("duplex")
    out.sync = true

    out_receiver = File.open(out.path, "rb")
    begin
      process.io.stdout = out
      process.io.stderr = out
      process.duplex = true

      process.start

      stdin = process.io.stdin

      stdin.puts "hello"
      stdin.flush
      wait_until { expect(rewind_and_read(out_receiver)).to match(/\Ahello\r?\n\z/m) }

      stdin.putc "n"
      stdin.flush
      wait_until { expect(rewind_and_read(out_receiver)).to match(/\Ahello\r?\nn\z/m) }

      stdin.print "e"
      stdin.flush
      wait_until { expect(rewind_and_read(out_receiver)).to match(/\Ahello\r?\nne\z/m) }

      stdin.printf "w"
      stdin.flush
      wait_until { expect(rewind_and_read(out_receiver)).to match(/\Ahello\r?\nnew\z/m) }

      stdin.write "\nworld\n"
      stdin.flush
      wait_until { expect(rewind_and_read(out_receiver)).to match(/\Ahello\r?\nnew\r?\nworld\r?\n\z/m) }

      stdin.close
      process.poll_for_exit(exit_timeout)
    ensure
      out_receiver.close
      out.close
    end
  end

  #
  # this works on JRuby 1.6.5 on my Mac, but for some reason
  # hangs on Travis (running 1.6.5.1 + OpenJDK).
  #
  # http://travis-ci.org/#!/enkessler/childprocess/jobs/487331
  #

  it "works with pipes" do
    process = ruby(<<-CODE)
      STDOUT.print "stdout"
      STDERR.print "stderr"
    CODE

    stdout, stdout_w = IO.pipe
    stderr, stderr_w = IO.pipe

    process.io.stdout = stdout_w
    process.io.stderr = stderr_w

    process.duplex = true

    process.start
    process.wait

    # write streams are closed *after* the process
    # has exited - otherwise it won't work on JRuby
    # with the current Process implementation

    stdout_w.close
    stderr_w.close

    out = stdout.read
    err = stderr.read

    expect([out, err]).to eq %w[stdout stderr]
  end

  it "can set close-on-exec when IO is inherited" do
    port = random_free_port
    server = TCPServer.new("127.0.0.1", port)
    ChildProcess.close_on_exec server

    process = sleeping_ruby
    process.io.inherit!

    process.start
    server.close

    wait_until { can_bind? "127.0.0.1", port }
  end

  it "handles long output" do
    process = ruby <<-CODE
    print 'a'*3000
    CODE

    out = Tempfile.new("long-output")
    out.sync = true

    begin
      process.io.stdout = out

      process.start
      process.wait

      expect(rewind_and_read(out).size).to eq 3000
    ensure
      out.close
    end
  end

  it 'should not inherit stdout and stderr by default' do
    cap = capture_std do
      process = echo
      process.start
      process.wait
    end

    expect(cap.stdout).to eq ''
    expect(cap.stderr).to eq ''
  end
end
