require 'rubygems' if RUBY_VERSION < '1.9.0'

require File.dirname(__FILE__) + '/../lib/os.rb' # load before sane to avoid sane being able to requir the gemified version...
require 'rspec' # rspec2

describe 'For Linux, (Ubuntu, Ubuntu 10.04 LTS) ' do
  before(:each) do
    ENV.should_receive(:[]).with('OS').any_number_of_times.and_return()
    ## Having difficulties finding a stub for RUBY_PLATFORM
    #  Looking into something like: http://stackoverflow.com/questions/1698335/can-i-use-rspec-mocks-to-stub-out-version-constants
    #  For now, simply using RbConfig::CONFIG
    # Kernel.stub!(:const_get).with('RUBY_PLATFORM').and_return("i686-linux")
    RbConfig::CONFIG.stub!(:[]).with('host_os').and_return('linux_gnu')
    RbConfig::CONFIG.stub!(:[]).with('host_cpu').and_return('i686')
  end

  describe OS do
    subject { OS } # class, not instance

    it { should be_linux }
    it { should be_posix }

    it { should_not be_mac }
    it { should_not be_osx }
    it { should_not be_windows }

  end

  describe OS::Underlying do
    subject { OS::Underlying } # class, not instance

    it { should be_linux }

    it { should_not be_bsd }
    it { should_not be_windows }
  end
end

