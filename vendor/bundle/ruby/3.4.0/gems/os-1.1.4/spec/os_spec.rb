require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe "OS" do

  it "identifies whether windows? or posix?" do
    if ENV['OS'] == 'Windows_NT'
      unless RUBY_PLATFORM =~ /cygwin/
        assert OS.windows? == true
        assert OS.doze? == true
        assert OS.posix? == false # can fail in error at times...I guess because some other spec has reset ENV on us...
      else
        assert OS::Underlying.windows?
        assert OS.windows? == false
        assert OS.posix? == true
      end
      assert OS::Underlying.windows?
    elsif [/linux/, /darwin/].any? {|posix_pattern| (RbConfig::CONFIG["host_os"] =~ posix_pattern) || RUBY_PLATFORM =~ posix_pattern }
      assert OS.windows? == false
      assert OS.posix? == true
      assert !OS::Underlying.windows?
    else
      pending "create test"
    end
  end

  it "has a bits method" do
    if RUBY_PLATFORM =~ /mingw32/
      assert OS.bits == 32
    elsif RUBY_PLATFORM =~ /64/ # linux...
      assert OS.bits == 64
    elsif RUBY_PLATFORM =~ /i686/
      assert OS.bits == 32
    elsif RUBY_PLATFORM =~ /java/ && RbConfig::CONFIG['host_os'] =~ /32$/
      assert OS.bits == 32
    elsif RUBY_PLATFORM =~ /java/ && RbConfig::CONFIG['host_cpu'] =~ /i386/
      assert OS.bits == 32
    elsif RUBY_PLATFORM =~ /i386/
      assert OS.bits == 32
    else
      pending "os bits not tested!" + RUBY_PLATFORM + ' ' +  RbConfig::CONFIG['host_os']
    end

  end

  it "should have an iron_ruby method" do
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'ironruby'
      assert OS.iron_ruby? == true
    else
      assert OS.iron_ruby? == false
    end
  end

  it "should know if you're on java" do
    if RUBY_PLATFORM == 'java'
      assert OS.java? == true # must be [true | false]
    else
      assert OS.java? == false
    end
  end

  it "should have a ruby_bin method" do
    if OS.windows?
      assert OS.ruby_bin.include?('.exe')
      if OS.iron_ruby?
        assert OS.ruby_bin.include?('ir.exe')
      else
        assert OS.ruby_bin.include?('ruby.exe')
      end
    else
      assert OS.ruby_bin.include?('ruby') && OS.ruby_bin.include?('/')
    end

    if OS.java?
      assert OS.ruby_bin.include?('jruby') # I think
    end

  end

  it "should have a cygwin? method" do
    if RUBY_PLATFORM =~ /cygwin/
      assert OS.cygwin? == true
    else
      assert OS.cygwin? == false
    end
  end

  it "should have a functional mac? method" do
    if RUBY_PLATFORM =~ /darwin/
      assert OS.mac? == true
    else
      if OS.host_os == 'darwin'
        assert OS.mac? == true
      else
        assert OS.mac? == false
      end
    end
  end

  it "should have a way to get rss_bytes on each platform" do
    bytes = OS.rss_bytes
    assert bytes > 0 # should always be true
    assert bytes.is_a?(Numeric) # don't want strings from any platform...
  end

  it "should tell you what the right /dev/null is" do
    if OS.windows?
      OS.dev_null.should == "NUL"
    else
      OS.dev_null.should == "/dev/null"
    end
  end

  it "should have a jruby method" do
    if defined?(RUBY_DESCRIPTION) && RUBY_DESCRIPTION =~ /^(jruby|java)/
      assert OS.jruby?
    else
      assert !OS.jruby?
    end
  end

  it "has working cpu count method" do
    cpu_count = OS.cpu_count
    assert cpu_count >= 1
    assert (cpu_count & (cpu_count - 1)) == 0 # CPU count is normally a power of 2
  end

  it "has working cpu count method with no env. variable" do
    OS.instance_variable_set(:@cpu_count, nil) # reset it
    if OS.windows?
      ENV.delete('NUMBER_OF_PROCESSORS')
      assert OS.cpu_count >= 1
    end
  end

  it "should have a start/open command helper" do
    if OS.doze?
      assert OS.open_file_command == "start"
    elsif OS.mac?
      assert OS.open_file_command == "open"
    else
      assert OS.open_file_command == "xdg-open"
    end
  end

  it "should provide a path to directory for application config" do
    ENV.stub(:[])

    if OS.mac?
      ENV.stub(:[]).with('HOME').and_return('/home/user')
      assert OS.app_config_path('appname') == '/home/xdg/Library/Application Support/appname'
    elsif OS.doze?
      # TODO
    else
      ENV.stub(:[]).with('HOME').and_return('/home/user')
      assert OS.app_config_path('appname') == '/home/user/.config/appname'

      ENV.stub(:[]).with('XDG_CONFIG_HOME').and_return('/home/xdg/.config')
      assert OS.app_config_path('appname') == '/home/xdg/.config/appname'
    end
  end

  it "should have a freebsd? method" do
    if OS.host_os =~ /freebsd/
      assert OS.freebsd? == true
    else
      assert OS.freebsd? == false
    end
  end

end

describe OS, "provides access to to underlying config values" do

  describe "#config, supplys the CONFIG hash" do
    subject { OS.config }

    specify { subject.should be_a(Hash) }

    it "should supply 'host_cpu'" do
      subject['host_cpu'].should eq(RbConfig::CONFIG['host_cpu'])
    end

    it "should supply 'host_os'" do
      subject['host_os'].should eq(RbConfig::CONFIG['host_os'])
    end
  end

  describe "by providing a delegate method for relevant keys in RbConfig::CONFIG" do
    %w(host host_cpu host_os).sort.each do |config_key|
      it "should delegate '#{config_key}'" do
        expected = "TEST #{config_key}"
        RbConfig::CONFIG.should_receive(:[]).with(config_key).and_return(expected)

        OS.send(config_key).should == expected
      end
    end
  end
end
