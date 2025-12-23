# frozen_string_literal: true

require "redis/commands/bitmaps"
require "redis/commands/cluster"
require "redis/commands/connection"
require "redis/commands/geo"
require "redis/commands/hashes"
require "redis/commands/hyper_log_log"
require "redis/commands/keys"
require "redis/commands/lists"
require "redis/commands/pubsub"
require "redis/commands/scripting"
require "redis/commands/server"
require "redis/commands/sets"
require "redis/commands/sorted_sets"
require "redis/commands/streams"
require "redis/commands/strings"
require "redis/commands/transactions"

class Redis
  module Commands
    include Bitmaps
    include Cluster
    include Connection
    include Geo
    include Hashes
    include HyperLogLog
    include Keys
    include Lists
    include Pubsub
    include Scripting
    include Server
    include Sets
    include SortedSets
    include Streams
    include Strings
    include Transactions

    # Commands returning 1 for true and 0 for false may be executed in a pipeline
    # where the method call will return nil. Propagate the nil instead of falsely
    # returning false.
    Boolify = lambda { |value|
      value != 0 unless value.nil?
    }

    BoolifySet = lambda { |value|
      case value
      when "OK"
        true
      when nil
        false
      else
        value
      end
    }

    Hashify = lambda { |value|
      if value.respond_to?(:each_slice)
        value.each_slice(2).to_h
      else
        value
      end
    }

    Pairify = lambda { |value|
      if value.respond_to?(:each_slice)
        value.each_slice(2).to_a
      else
        value
      end
    }

    Floatify = lambda { |value|
      case value
      when "inf"
        Float::INFINITY
      when "-inf"
        -Float::INFINITY
      when String
        Float(value)
      else
        value
      end
    }

    FloatifyPairs = lambda { |value|
      return value unless value.respond_to?(:each_slice)

      value.each_slice(2).map do |member, score|
        [member, Floatify.call(score)]
      end
    }

    HashifyInfo = lambda { |reply|
      lines = reply.split("\r\n").grep_v(/^(#|$)/)
      lines.map! { |line| line.split(':', 2) }
      lines.compact!
      lines.to_h
    }

    HashifyStreams = lambda { |reply|
      case reply
      when nil
        {}
      else
        reply.map { |key, entries| [key, HashifyStreamEntries.call(entries)] }.to_h
      end
    }

    EMPTY_STREAM_RESPONSE = [nil].freeze
    private_constant :EMPTY_STREAM_RESPONSE

    HashifyStreamEntries = lambda { |reply|
      reply.compact.map do |entry_id, values|
        [entry_id, values&.each_slice(2)&.to_h]
      end
    }

    HashifyStreamAutoclaim = lambda { |reply|
      {
        'next' => reply[0],
        'entries' => reply[1].compact.map do |entry, values|
          [entry, values.each_slice(2)&.to_h]
        end
      }
    }

    HashifyStreamAutoclaimJustId = lambda { |reply|
      {
        'next' => reply[0],
        'entries' => reply[1]
      }
    }

    HashifyStreamPendings = lambda { |reply|
      {
        'size' => reply[0],
        'min_entry_id' => reply[1],
        'max_entry_id' => reply[2],
        'consumers' => reply[3].nil? ? {} : reply[3].to_h
      }
    }

    HashifyStreamPendingDetails = lambda { |reply|
      reply.map do |arr|
        {
          'entry_id' => arr[0],
          'consumer' => arr[1],
          'elapsed' => arr[2],
          'count' => arr[3]
        }
      end
    }

    HashifyClusterNodeInfo = lambda { |str|
      arr = str.split(' ')
      {
        'node_id' => arr[0],
        'ip_port' => arr[1],
        'flags' => arr[2].split(','),
        'master_node_id' => arr[3],
        'ping_sent' => arr[4],
        'pong_recv' => arr[5],
        'config_epoch' => arr[6],
        'link_state' => arr[7],
        'slots' => arr[8].nil? ? nil : Range.new(*arr[8].split('-'))
      }
    }

    HashifyClusterSlots = lambda { |reply|
      reply.map do |arr|
        first_slot, last_slot = arr[0..1]
        master = { 'ip' => arr[2][0], 'port' => arr[2][1], 'node_id' => arr[2][2] }
        replicas = arr[3..-1].map { |r| { 'ip' => r[0], 'port' => r[1], 'node_id' => r[2] } }
        {
          'start_slot' => first_slot,
          'end_slot' => last_slot,
          'master' => master,
          'replicas' => replicas
        }
      end
    }

    HashifyClusterNodes = lambda { |reply|
      reply.split(/[\r\n]+/).map { |str| HashifyClusterNodeInfo.call(str) }
    }

    HashifyClusterSlaves = lambda { |reply|
      reply.map { |str| HashifyClusterNodeInfo.call(str) }
    }

    Noop = ->(reply) { reply }

    # Sends a command to Redis and returns its reply.
    #
    # Replies are converted to Ruby objects according to the RESP protocol, so
    # you can expect a Ruby array, integer or nil when Redis sends one. Higher
    # level transformations, such as converting an array of pairs into a Ruby
    # hash, are up to consumers.
    #
    # Redis error replies are raised as Ruby exceptions.
    def call(*command)
      send_command(command)
    end

    # Interact with the sentinel command (masters, master, slaves, failover)
    #
    # @param [String] subcommand e.g. `masters`, `master`, `slaves`
    # @param [Array<String>] args depends on subcommand
    # @return [Array<String>, Hash<String, String>, String] depends on subcommand
    def sentinel(subcommand, *args)
      subcommand = subcommand.to_s.downcase
      send_command([:sentinel, subcommand] + args) do |reply|
        case subcommand
        when "get-master-addr-by-name"
          reply
        else
          if reply.is_a?(Array)
            if reply[0].is_a?(Array)
              reply.map(&Hashify)
            else
              Hashify.call(reply)
            end
          else
            reply
          end
        end
      end
    end

    private

    def method_missing(*command) # rubocop:disable Style/MissingRespondToMissing
      send_command(command)
    end
  end
end
