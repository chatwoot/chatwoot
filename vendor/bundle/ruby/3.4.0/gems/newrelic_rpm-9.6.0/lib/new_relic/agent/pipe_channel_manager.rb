# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'base64'

module NewRelic
  module Agent
    #--
    # Manages the registering and servicing of pipes used by child
    # processes to report data to their parent, rather than directly
    # to the collector.
    module PipeChannelManager
      extend self

      def register_report_channel(id)
        listener.register_pipe(id)
      end

      def channels
        listener.pipes
      end

      def listener
        @listener ||= Listener.new
      end

      # Expected initial sequence of events for Pipe usage:
      #
      # 1. Pipe is created in parent process (read and write ends open)
      # 2. Parent process forks
      # 3. An after_fork hook is invoked in the child
      # 4. From after_fork hook, child closes read end of pipe, and
      #    writes a ready marker on the pipe (after_fork_in_child).
      # 5. The parent receives the ready marker, and closes the write end of the
      #    pipe in response (after_fork_in_parent).
      #
      # After this sequence of steps, an exit (whether clean or not) of the
      # child will result in the pipe being marked readable again, and giving an
      # EOF marker (nil) when read. Note that closing of the unused ends of the
      # pipe in the parent and child processes is essential in order for the EOF
      # to be correctly triggered. The ready marker mechanism is used because
      # there's no easy hook for after_fork in the parent process.
      #
      # This class provides message framing (separation of individual messages),
      # but not serialization. Serialization / deserialization is the
      # responsibility of clients.
      #
      # Message framing works like this:
      #
      # Each message sent across the pipe is preceded by a length tag that
      # specifies the length of the message that immediately follows, in bytes.
      # The length tags are serialized as unsigned big-endian long values, (4
      # bytes each). This means that the maximum theoretical message size is
      # 4 GB - much larger than we'd ever need or want for this application.
      #
      class Pipe
        READY_MARKER = 'READY'
        NUM_LENGTH_BYTES = 4

        attr_accessor :in, :out
        attr_reader :last_read, :parent_pid

        def initialize
          @out, @in = IO.pipe
          if defined?(::Encoding::ASCII_8BIT)
            @in.set_encoding(::Encoding::ASCII_8BIT)
          end
          @last_read = Process.clock_gettime(Process::CLOCK_REALTIME)
          @parent_pid = $$
        end

        def close
          @out.close unless @out.closed?
          @in.close unless @in.closed?
        end

        def serialize_message_length(data)
          [data.bytesize].pack('L>')
        end

        def deserialize_message_length(data)
          data.unpack('L>').first
        end

        def write(data)
          @out.close unless @out.closed?
          @in << serialize_message_length(data)
          @in << data
        end

        def read
          @in.close unless @in.closed?
          @last_read = Process.clock_gettime(Process::CLOCK_REALTIME)
          length_bytes = @out.read(NUM_LENGTH_BYTES)
          if length_bytes
            message_length = deserialize_message_length(length_bytes)
            if message_length
              @out.read(message_length)
            else
              length_hex = length_bytes.bytes.map { |b| b.to_s(16) }.join(' ')
              NewRelic::Agent.logger.error("Failed to deserialize message length from pipe. Bytes: [#{length_hex}]")
              nil
            end
          else
            NewRelic::Agent.logger.error('Failed to read bytes for length from pipe.')
            nil
          end
        end

        def eof?
          !@out.closed? && @out.eof?
        end

        def after_fork_in_child
          @out.close unless @out.closed?
          write(READY_MARKER)
        end

        def after_fork_in_parent
          @in.close unless @in.closed?
        end

        def closed?
          @out.closed? && @in.closed?
        end
      end

      class Listener
        attr_reader :thread

        # This attr_accessor intentionally provides unsynchronized access to the
        # @pipes hash. It is used to look up the write end of the pipe from
        # within the Resque child process, and must be unsynchronized in order
        # to avoid a potential deadlock in which the PipeChannelManager::Listener
        # thread in the parent process is holding the @pipes_lock at the time of
        # the fork.
        attr_accessor :pipes, :timeout, :select_timeout

        def initialize
          @started = nil
          @pipes = {}
          @pipes_lock = Mutex.new

          @timeout = 360
          @select_timeout = 60
        end

        def wakeup
          wake.in << '.'
        end

        def register_pipe(id)
          @pipes_lock.synchronize do
            @pipes[id] = Pipe.new
          end

          wakeup
        end

        def start
          return if @started == true

          @started = true
          @thread = NewRelic::Agent::Threading::AgentThread.create('Pipe Channel Manager') do
            now = nil
            loop do
              clean_up_pipes

              pipes_to_listen_to = @pipes_lock.synchronize do
                @pipes.values.map { |pipe| pipe.out } + [wake.out]
              end

              if now
                NewRelic::Agent.record_metric(
                  'Supportability/Listeners',
                  Process.clock_gettime(Process::CLOCK_REALTIME) - now
                )
              end

              if ready = IO.select(pipes_to_listen_to, [], [], @select_timeout)
                now = Process.clock_gettime(Process::CLOCK_REALTIME)

                ready_pipes = ready[0]
                ready_pipes.each do |pipe|
                  merge_data_from_pipe(pipe) unless pipe == wake.out
                end

                begin
                  wake.out.read_nonblock(1) if ready_pipes.include?(wake.out)
                rescue IO::WaitReadable
                  NewRelic::Agent.logger.error('Issue while reading from the ready pipe')
                  NewRelic::Agent.logger.error("Ready pipes: #{ready_pipes.map(&:to_s)}, wake.out pipe: #{wake.out}")
                end
              end

              break unless should_keep_listening?
            end
          end
          sleep(0.001) # give time for the thread to spawn
        end

        def stop_listener_thread
          @started = false
          wakeup
          @thread.join
        end

        def stop
          return unless @started == true

          stop_listener_thread
          close_all_pipes
          @wake.close
          @wake = nil
        end

        def close_all_pipes
          @pipes_lock.synchronize do
            @pipes.each do |id, pipe|
              # Needs else branch coverage
              pipe.close if pipe # rubocop:disable Style/SafeNavigation
            end
            @pipes = {}
          end
        end

        def wake
          @wake ||= Pipe.new
        end

        def started?
          @started
        end

        protected

        def merge_data_from_pipe(pipe_handle)
          pipe = find_pipe_for_handle(pipe_handle)
          raw_payload = pipe.read
          if raw_payload && !raw_payload.empty?
            if raw_payload == Pipe::READY_MARKER
              pipe.after_fork_in_parent
            else
              payload = unmarshal(raw_payload)
              if payload
                endpoint, items = payload
                NewRelic::Agent.agent.merge_data_for_endpoint(endpoint, items)
              end
            end
          end

          pipe.close if pipe.eof?
        end

        def unmarshal(data)
          Marshal.load(data)
        rescue StandardError => e
          ::NewRelic::Agent.logger.error('Failure unmarshalling message from Resque child process', e)
          ::NewRelic::Agent.logger.debug(Base64.encode64(data))
          nil
        end

        def should_keep_listening?
          @started || @pipes_lock.synchronize { @pipes.values.find { |pipe| !pipe.in.closed? } }
        end

        def clean_up_pipes
          @pipes_lock.synchronize do
            @pipes.values.each do |pipe|
              if pipe.last_read + @timeout < Process.clock_gettime(Process::CLOCK_REALTIME)
                pipe.close unless pipe.closed?
              end
            end
            @pipes.reject! { |id, pipe| pipe.out.closed? }
          end
        end

        def find_pipe_for_handle(out_handle)
          @pipes_lock.synchronize do
            @pipes.values.find { |pipe| pipe.out == out_handle }
          end
        end
      end
    end
  end
end
