require_relative '../process_spawn_process'

module ChildProcess
  module Unix
    class Process < ProcessSpawnProcess
      def io
        @io ||= Unix::IO.new
      end

      def stop(timeout = 3)
        assert_started
        send_term

        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end

        send_kill
        wait
      rescue Errno::ECHILD, Errno::ESRCH
        # handle race condition where process dies between timeout
        # and send_kill
        true
      end
    end # Process
  end # Unix
end # ChildProcess
