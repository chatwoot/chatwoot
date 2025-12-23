# frozen_string_literal: true

#
# This code is based on https://github.com/fohte/rubocop-daemon.
#
# Copyright (c) 2018 Hayato Kawai
#
# The MIT License (MIT)
#
# https://github.com/fohte/rubocop-daemon/blob/master/LICENSE.txt
#
module RuboCop
  module Server
    module ClientCommand
      # This class is a client command to execute server process.
      # @api private
      class Exec < Base
        def run
          ensure_server!
          read_stdin = ARGV.include?('-s') || ARGV.include?('--stdin')
          send_request(
            command: 'exec',
            args: ARGV.dup,
            body: read_stdin ? $stdin.read : ''
          )
          warn stderr unless stderr.empty?
          status
        end

        private

        def ensure_server!
          if incompatible_version?
            warn 'RuboCop version incompatibility found, RuboCop server restarting...'
            ClientCommand::Stop.new.run
          elsif check_running_server
            return
          end

          ClientCommand::Start.new.run
        end

        def incompatible_version?
          Cache.version_path.read != Cache.restart_key
        end

        def stderr
          Cache.stderr_path.read
        end

        def status
          unless Cache.status_path.file?
            raise "RuboCop server: Could not find status file at: #{Cache.status_path}"
          end

          status = Cache.status_path.read
          raise "RuboCop server: '#{status}' is not a valid status!" unless /\A\d+\z/.match?(status)

          status.to_i
        end
      end
    end
  end
end
