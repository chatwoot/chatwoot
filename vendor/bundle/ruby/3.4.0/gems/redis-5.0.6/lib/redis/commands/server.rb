# frozen_string_literal: true

class Redis
  module Commands
    module Server
      # Asynchronously rewrite the append-only file.
      #
      # @return [String] `OK`
      def bgrewriteaof
        send_command([:bgrewriteaof])
      end

      # Asynchronously save the dataset to disk.
      #
      # @return [String] `OK`
      def bgsave
        send_command([:bgsave])
      end

      # Get or set server configuration parameters.
      #
      # @param [Symbol] action e.g. `:get`, `:set`, `:resetstat`
      # @return [String, Hash] string reply, or hash when retrieving more than one
      #   property with `CONFIG GET`
      def config(action, *args)
        send_command([:config, action] + args) do |reply|
          if reply.is_a?(Array) && action == :get
            Hashify.call(reply)
          else
            reply
          end
        end
      end

      # Manage client connections.
      #
      # @param [String, Symbol] subcommand e.g. `kill`, `list`, `getname`, `setname`
      # @return [String, Hash] depends on subcommand
      def client(subcommand, *args)
        send_command([:client, subcommand] + args) do |reply|
          if subcommand.to_s == "list"
            reply.lines.map do |line|
              entries = line.chomp.split(/[ =]/)
              Hash[entries.each_slice(2).to_a]
            end
          else
            reply
          end
        end
      end

      # Return the number of keys in the selected database.
      #
      # @return [Integer]
      def dbsize
        send_command([:dbsize])
      end

      # Remove all keys from all databases.
      #
      # @param [Hash] options
      #   - `:async => Boolean`: async flush (default: false)
      # @return [String] `OK`
      def flushall(options = nil)
        if options && options[:async]
          send_command(%i[flushall async])
        else
          send_command([:flushall])
        end
      end

      # Remove all keys from the current database.
      #
      # @param [Hash] options
      #   - `:async => Boolean`: async flush (default: false)
      # @return [String] `OK`
      def flushdb(options = nil)
        if options && options[:async]
          send_command(%i[flushdb async])
        else
          send_command([:flushdb])
        end
      end

      # Get information and statistics about the server.
      #
      # @param [String, Symbol] cmd e.g. "commandstats"
      # @return [Hash<String, String>]
      def info(cmd = nil)
        send_command([:info, cmd].compact) do |reply|
          if reply.is_a?(String)
            reply = HashifyInfo.call(reply)

            if cmd && cmd.to_s == "commandstats"
              # Extract nested hashes for INFO COMMANDSTATS
              reply = Hash[reply.map do |k, v|
                v = v.split(",").map { |e| e.split("=") }
                [k[/^cmdstat_(.*)$/, 1], Hash[v]]
              end]
            end
          end

          reply
        end
      end

      # Get the UNIX time stamp of the last successful save to disk.
      #
      # @return [Integer]
      def lastsave
        send_command([:lastsave])
      end

      # Listen for all requests received by the server in real time.
      #
      # There is no way to interrupt this command.
      #
      # @yield a block to be called for every line of output
      # @yieldparam [String] line timestamp and command that was executed
      def monitor
        synchronize do |client|
          client = client.pubsub
          client.call_v([:monitor])
          loop do
            yield client.next_event
          end
        end
      end

      # Synchronously save the dataset to disk.
      #
      # @return [String]
      def save
        send_command([:save])
      end

      # Synchronously save the dataset to disk and then shut down the server.
      def shutdown
        synchronize do |client|
          client.disable_reconnection do
            client.call_v([:shutdown])
          rescue ConnectionError
            # This means Redis has probably exited.
            nil
          end
        end
      end

      # Make the server a slave of another instance, or promote it as master.
      def slaveof(host, port)
        send_command([:slaveof, host, port])
      end

      # Interact with the slowlog (get, len, reset)
      #
      # @param [String] subcommand e.g. `get`, `len`, `reset`
      # @param [Integer] length maximum number of entries to return
      # @return [Array<String>, Integer, String] depends on subcommand
      def slowlog(subcommand, length = nil)
        args = [:slowlog, subcommand]
        args << Integer(length) if length
        send_command(args)
      end

      # Internal command used for replication.
      def sync
        send_command([:sync])
      end

      # Return the server time.
      #
      # @example
      #   r.time # => [ 1333093196, 606806 ]
      #
      # @return [Array<Integer>] tuple of seconds since UNIX epoch and
      #   microseconds in the current second
      def time
        send_command([:time]) do |reply|
          reply&.map(&:to_i)
        end
      end

      def debug(*args)
        send_command([:debug] + args)
      end
    end
  end
end
