require 'rbconfig'
require 'yaml'

# a set of friendly files for determining your Ruby runtime
# treats cygwin as linux
# also treats IronRuby on mono as...linux
class OS
  attr_reader :config

  def self.config
    @config ||= RbConfig::CONFIG
  end

  # true if on windows [and/or jruby]
  # false if on linux or cygwin on windows

  def self.windows?
    @windows ||= begin
      if RUBY_PLATFORM =~ /cygwin/ # i386-cygwin
        false
      elsif ENV['OS'] == 'Windows_NT'
        true
      else
        false
      end
    end

  end

  # true for linux, os x, cygwin
  def self.posix?
    @posix ||=
    begin
      if OS.windows?
        begin
          begin
            # what if we're on interix...
            # untested, of course
            Process.wait fork{}
            true
          rescue NotImplementedError, NoMethodError
            false
          end
        end
      else
        # assume non windows is posix
        true
      end
    end

  end

  # true for linux, false for windows, os x, cygwin
  def self.linux?
    if (host_os =~ /linux/)
      true
    else
      false
    end
  end

  def self.freebsd?
    if (host_os =~ /freebsd/)
      true
    else
      false
    end
  end

  def self.iron_ruby?
   @iron_ruby ||= begin
     if defined?(RUBY_ENGINE) && (RUBY_ENGINE == 'ironruby')
       true
     else
       false
     end
   end
  end

  def self.bits
    @bits ||= begin
      if host_cpu =~ /_64$/ || RUBY_PLATFORM =~ /x86_64/
        64
      elsif RUBY_PLATFORM == 'java' && ENV_JAVA['sun.arch.data.model'] # "32" or "64":http://www.ruby-forum.com/topic/202173#880613
        ENV_JAVA['sun.arch.data.model'].to_i
      elsif host_cpu == 'i386'
        32
      elsif host_os =~ /32$/ # mingw32, mswin32
        32
      else # cygwin only...I think
        if 1.size == 8
          64
        else
          32
        end
      end
    end
  end


  def self.java?
    @java ||= begin
      if RUBY_PLATFORM =~ /java/
        true
      else
        false
      end
    end
  end

  def self.ruby_bin
    @ruby_exe ||= begin
      File::join(config['bindir'], config['ruby_install_name']) + config['EXEEXT']
    end
  end

  def self.mac?
    @mac = begin
      if host_os =~ /darwin/
        true
      else
        false
      end
    end
  end

  def self.osx?
    mac?
  end

  def self.x?
    mac?
  end


  # amount of memory the current process "is using", in RAM
  # (doesn't include any swap memory that it may be using, just that in actual RAM)
  # raises 'unknown' on jruby currently
  def self.rss_bytes
    # attempt to do this in a jruby friendly way
    if OS::Underlying.windows?
      # MRI, Java, IronRuby, Cygwin
      if OS.java?
        # no win32ole on 1.5.x, so leave here for compatibility...maybe for awhile :P
        require 'java'
        mem_bean = java.lang.management.ManagementFactory.getMemoryMXBean
        mem_bean.heap_memory_usage.used + mem_bean.non_heap_memory_usage.used
      else
        wmi = nil
        begin
          require 'win32ole'
          wmi = WIN32OLE.connect("winmgmts://")
        rescue LoadError, NoMethodError => e # NoMethod for IronRuby currently [sigh]
          raise 'rss unknown for this platform ' + e.to_s
        end
        processes = wmi.ExecQuery("select * from win32_process where ProcessId = #{Process.pid}")
        memory_used = nil
        # only allow for one process...
        for process in processes
          raise "multiple processes same pid?" if memory_used
          memory_used = process.WorkingSetSize.to_i
        end
        memory_used
      end
    elsif OS.posix? # linux [though I've heard it works in OS X]
      `ps -o rss= -p #{Process.pid}`.to_i * 1024 # in kiloBytes
    else
      raise 'unknown rss for this platform'
    end
  end

  class Underlying

    def self.bsd?
      OS.osx?
    end

    def self.windows?
      ENV['OS'] == 'Windows_NT'
    end

    def self.linux?
      OS.host_os =~ /linux/ ? true : false
    end

    def self.docker?
      system('grep -q docker /proc/self/cgroup') if OS.linux?
    end

  end

  def self.cygwin?
    @cygwin = begin
      if RUBY_PLATFORM =~ /-cygwin/
        true
      else
        false
      end
    end
  end

  def self.dev_null # File::NULL in 1.9.3+
    @dev_null ||= begin
      if OS.windows?
        "NUL"
      else
        "/dev/null"
      end
    end
  end

  # provides easy way to see the relevant config entries
  def self.report
    relevant_keys = [
      'arch',
      'host',
      'host_cpu',
      'host_os',
      'host_vendor',
      'target',
      'target_cpu',
      'target_os',
      'target_vendor',
    ]
    RbConfig::CONFIG.reject {|key, val| !relevant_keys.include? key }.merge({'RUBY_PLATFORM' => RUBY_PLATFORM}).to_yaml
  end

  def self.cpu_count
    @cpu_count ||=
    case RUBY_PLATFORM
    when /darwin9/
      `hwprefs cpu_count`.to_i
    when /darwin10/
      (hwprefs_available? ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    when /freebsd/
      `sysctl -n hw.ncpu`.to_i
    else
      if RbConfig::CONFIG['host_os'] =~ /darwin/
         (hwprefs_available? ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
      elsif self.windows?
        # ENV counts hyper threaded...not good.
      	      # out = ENV['NUMBER_OF_PROCESSORS'].to_i
        require 'win32ole'
        wmi = WIN32OLE.connect("winmgmts://")
        cpu = wmi.ExecQuery("select NumberOfCores from Win32_Processor") # don't count hyper-threaded in this
        cpu.to_enum.first.NumberOfCores
      else
        raise 'unknown platform processor_count'
      end
    end
  end

  def self.open_file_command
    if OS.doze? || OS.cygwin?
      "start"
    elsif OS.mac?
      "open"
    else
      # linux...what about cygwin?
      "xdg-open"
    end

  end

  def self.app_config_path(name)
    if OS.doze?
      if ENV['LOCALAPPDATA']
        return File.join(ENV['LOCALAPPDATA'], name)
      end

      File.join ENV['USERPROFILE'], 'Local Settings', 'Application Data', name
    elsif OS.mac?
      File.join ENV['HOME'], 'Library', 'Application Support', name
    else
      if ENV['XDG_CONFIG_HOME']
        return File.join(ENV['XDG_CONFIG_HOME'], name)
      end

      File.join ENV['HOME'], '.config', name
    end
  end

  def self.parse_os_release
    if OS.linux? && File.exist?('/etc/os-release')
      output = {}

      File.read('/etc/os-release').each_line do |line|
        parsed_line = line.chomp.tr('"', '').split('=')
        next if parsed_line.empty?
        output[parsed_line[0].to_sym] = parsed_line[1]
      end
      output
    else
      raise "File /etc/os-release doesn't exists or not Linux"
    end
  end

  class << self
    alias :doze? :windows? # a joke name but I use it and like it :P
    alias :jruby? :java?

    # delegators for relevant config values
    %w(host host_cpu host_os).each do |method_name|
      define_method(method_name) { config[method_name] }
    end

  end

  private

  def self.hwprefs_available?
    `which hwprefs` != ''
  end

end
