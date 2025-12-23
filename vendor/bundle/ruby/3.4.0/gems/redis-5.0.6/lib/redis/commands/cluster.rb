# frozen_string_literal: true

class Redis
  module Commands
    module Cluster
      # Sends `CLUSTER *` command to random node and returns its reply.
      #
      # @see https://redis.io/commands#cluster Reference of cluster command
      #
      # @param subcommand [String, Symbol] the subcommand of cluster command
      #   e.g. `:slots`, `:nodes`, `:slaves`, `:info`
      #
      # @return [Object] depends on the subcommand
      def cluster(subcommand, *args)
        send_command([:cluster, subcommand] + args)
      end

      # Sends `ASKING` command to random node and returns its reply.
      #
      # @see https://redis.io/topics/cluster-spec#ask-redirection ASK redirection
      #
      # @return [String] `'OK'`
      def asking
        send_command(%i[asking])
      end
    end
  end
end
