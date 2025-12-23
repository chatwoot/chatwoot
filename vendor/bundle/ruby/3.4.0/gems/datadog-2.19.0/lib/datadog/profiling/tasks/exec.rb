# frozen_string_literal: true

module Datadog
  module Profiling
    module Tasks
      # Wraps command with Datadog profiling
      class Exec
        attr_reader :args

        def initialize(args)
          @args = args
        end

        def run
          set_rubyopt!
          exec_with_error_handling(args)
        end

        def rubyopts
          [
            "-rdatadog/profiling/preload"
          ]
        end

        private

        def set_rubyopt!
          existing_rubyopt = ENV["RUBYOPT"]

          ENV["RUBYOPT"] = existing_rubyopt ? "#{existing_rubyopt} #{rubyopts.join(" ")}" : rubyopts.join(" ")
        end

        # If there's an error here, rather than throwing a cryptic stack trace, let's instead have clearer messages, and
        # follow the same status codes as the shell uses
        # See also:
        # * https://www.gnu.org/software/bash/manual/html_node/Exit-Status.html
        # * https://github.com/rubygems/rubygems/blob/dd93966cac224532035deda533cba2685dfa30cc/bundler/lib/bundler/cli/exec.rb#L45
        def exec_with_error_handling(args)
          Kernel.exec(*args)
        rescue Errno::ENOENT => e
          Kernel.warn "ddprofrb exec failed: #{e.class.name} #{e.message} (command was '#{args.join(" ")}')"
          Kernel.exit 127
        rescue Errno::EACCES, Errno::ENOEXEC => e
          Kernel.warn "ddprofrb exec failed: #{e.class.name} #{e.message} (command was '#{args.join(" ")}')"
          Kernel.exit 126
        end
      end
    end
  end
end
