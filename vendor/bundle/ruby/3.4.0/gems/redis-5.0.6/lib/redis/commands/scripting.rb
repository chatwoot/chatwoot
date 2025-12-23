# frozen_string_literal: true

class Redis
  module Commands
    module Scripting
      # Control remote script registry.
      #
      # @example Load a script
      #   sha = redis.script(:load, "return 1")
      #     # => <sha of this script>
      # @example Check if a script exists
      #   redis.script(:exists, sha)
      #     # => true
      # @example Check if multiple scripts exist
      #   redis.script(:exists, [sha, other_sha])
      #     # => [true, false]
      # @example Flush the script registry
      #   redis.script(:flush)
      #     # => "OK"
      # @example Kill a running script
      #   redis.script(:kill)
      #     # => "OK"
      #
      # @param [String] subcommand e.g. `exists`, `flush`, `load`, `kill`
      # @param [Array<String>] args depends on subcommand
      # @return [String, Boolean, Array<Boolean>, ...] depends on subcommand
      #
      # @see #eval
      # @see #evalsha
      def script(subcommand, *args)
        subcommand = subcommand.to_s.downcase

        if subcommand == "exists"
          arg = args.first

          send_command([:script, :exists, arg]) do |reply|
            reply = reply.map { |r| Boolify.call(r) }

            if arg.is_a?(Array)
              reply
            else
              reply.first
            end
          end
        else
          send_command([:script, subcommand] + args)
        end
      end

      # Evaluate Lua script.
      #
      # @example EVAL without KEYS nor ARGV
      #   redis.eval("return 1")
      #     # => 1
      # @example EVAL with KEYS and ARGV as array arguments
      #   redis.eval("return { KEYS, ARGV }", ["k1", "k2"], ["a1", "a2"])
      #     # => [["k1", "k2"], ["a1", "a2"]]
      # @example EVAL with KEYS and ARGV in a hash argument
      #   redis.eval("return { KEYS, ARGV }", :keys => ["k1", "k2"], :argv => ["a1", "a2"])
      #     # => [["k1", "k2"], ["a1", "a2"]]
      #
      # @param [Array<String>] keys optional array with keys to pass to the script
      # @param [Array<String>] argv optional array with arguments to pass to the script
      # @param [Hash] options
      #   - `:keys => Array<String>`: optional array with keys to pass to the script
      #   - `:argv => Array<String>`: optional array with arguments to pass to the script
      # @return depends on the script
      #
      # @see #script
      # @see #evalsha
      def eval(*args)
        _eval(:eval, args)
      end

      # Evaluate Lua script by its SHA.
      #
      # @example EVALSHA without KEYS nor ARGV
      #   redis.evalsha(sha)
      #     # => <depends on script>
      # @example EVALSHA with KEYS and ARGV as array arguments
      #   redis.evalsha(sha, ["k1", "k2"], ["a1", "a2"])
      #     # => <depends on script>
      # @example EVALSHA with KEYS and ARGV in a hash argument
      #   redis.evalsha(sha, :keys => ["k1", "k2"], :argv => ["a1", "a2"])
      #     # => <depends on script>
      #
      # @param [Array<String>] keys optional array with keys to pass to the script
      # @param [Array<String>] argv optional array with arguments to pass to the script
      # @param [Hash] options
      #   - `:keys => Array<String>`: optional array with keys to pass to the script
      #   - `:argv => Array<String>`: optional array with arguments to pass to the script
      # @return depends on the script
      #
      # @see #script
      # @see #eval
      def evalsha(*args)
        _eval(:evalsha, args)
      end

      private

      def _eval(cmd, args)
        script = args.shift
        options = args.pop if args.last.is_a?(Hash)
        options ||= {}

        keys = args.shift || options[:keys] || []
        argv = args.shift || options[:argv] || []

        send_command([cmd, script, keys.length] + keys + argv)
      end
    end
  end
end
