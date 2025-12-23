# frozen_string_literal: true
module Parallel
  # TODO: inline this method into parallel.rb and kill physical_processor_count in next major release
  module ProcessorCount
    # Number of processors seen by the OS, used for process scheduling
    def processor_count
      require 'etc'
      @processor_count ||= Integer(ENV['PARALLEL_PROCESSOR_COUNT'] || Etc.nprocessors)
    end

    # Number of physical processor cores on the current system.
    def physical_processor_count
      @physical_processor_count ||= begin
        ppc =
          case RbConfig::CONFIG["target_os"]
          when /darwin[12]/
            IO.popen("/usr/sbin/sysctl -n hw.physicalcpu").read.to_i
          when /linux/
            cores = {} # unique physical ID / core ID combinations
            phy = 0
            File.read("/proc/cpuinfo").scan(/^physical id.*|^core id.*/) do |ln|
              if ln.start_with?("physical")
                phy = ln[/\d+/]
              elsif ln.start_with?("core")
                cid = "#{phy}:#{ln[/\d+/]}"
                cores[cid] = true unless cores[cid]
              end
            end
            cores.count
          when /mswin|mingw/
            require 'win32ole'
            result_set = WIN32OLE.connect("winmgmts://").ExecQuery(
              "select NumberOfCores from Win32_Processor"
            )
            result_set.to_enum.collect(&:NumberOfCores).reduce(:+)
          else
            processor_count
          end
        # fall back to logical count if physical info is invalid
        ppc > 0 ? ppc : processor_count
      end
    end
  end
end
