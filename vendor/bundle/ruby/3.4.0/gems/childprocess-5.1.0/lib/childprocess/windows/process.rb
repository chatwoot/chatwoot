require_relative '../process_spawn_process'

module ChildProcess
  module Windows
    class Process < ProcessSpawnProcess
      def io
        @io ||= Windows::IO.new
      end

      def stop(timeout = 3)
        assert_started
        send_kill

        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end

        wait
      rescue Errno::ECHILD, Errno::ESRCH
        # handle race condition where process dies between timeout
        # and send_kill
        true
      end
    end # Process
  end # Windows
end # ChildProcess
