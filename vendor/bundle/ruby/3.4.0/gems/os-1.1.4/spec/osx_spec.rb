require File.expand_path('spec_helper.rb', File.dirname(__FILE__))

describe 'For OSX (Snow Leopard, 10.6),' do
  before(:each) do
    ENV.stub!(:[]).with('OS').and_return(nil)
    # Issues stubbing RUBY_PLATFORM, using RbConfig instead.
    # Kernel.stub!(:RUBY_PLATFORM => "x86_64-darwin10.6")
    RbConfig::CONFIG.stub!(:[]).with('host_os').and_return("darwin10.6.0")
    RbConfig::CONFIG.stub!(:[]).with('host_cpu').and_return('i386')
  end

  describe OS do
    subject { OS } # class, not instance

    it { should be_mac }
    it { should be_x } # OS.x?
    it { should be_osx }
    it { should be_posix }

    it { should_not be_windows }

  end

  describe OS::Underlying do
    subject { OS::Underlying } # class, not instance

    it { should be_bsd }
    it { should_not be_windows }
  end
end
