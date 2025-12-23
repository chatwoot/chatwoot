# frozen_string_literal: false

require_relative "nop"

module IRB
  # :stopdoc:

  module ExtendCommand
    class IrbInfo < Nop
      category "IRB"
      description "Show information about IRB."

      def execute
        str  = "Ruby version: #{RUBY_VERSION}\n"
        str += "IRB version: #{IRB.version}\n"
        str += "InputMethod: #{IRB.CurrentContext.io.inspect}\n"
        str += ".irbrc path: #{IRB.rc_file}\n" if File.exist?(IRB.rc_file)
        str += "RUBY_PLATFORM: #{RUBY_PLATFORM}\n"
        str += "LANG env: #{ENV["LANG"]}\n" if ENV["LANG"] && !ENV["LANG"].empty?
        str += "LC_ALL env: #{ENV["LC_ALL"]}\n" if ENV["LC_ALL"] && !ENV["LC_ALL"].empty?
        str += "East Asian Ambiguous Width: #{Reline.ambiguous_width.inspect}\n"
        if RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
          codepage = `chcp`.b.sub(/.*: (\d+)\n/, '\1')
          str += "Code page: #{codepage}\n"
        end
        puts str
        nil
      end
    end
  end

  # :startdoc:
end
