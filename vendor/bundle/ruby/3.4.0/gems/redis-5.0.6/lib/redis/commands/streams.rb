# frozen_string_literal: true

class Redis
  module Commands
    module Streams
      # Returns the stream information each subcommand.
      #
      # @example stream
      #   redis.xinfo(:stream, 'mystream')
      # @example groups
      #   redis.xinfo(:groups, 'mystream')
      # @example consumers
      #   redis.xinfo(:consumers, 'mystream', 'mygroup')
      #
      # @param subcommand [String] e.g. `stream` `groups` `consumers`
      # @param key        [String] the stream key
      # @param group      [String] the consumer group name, required if subcommand is `consumers`
      #
      # @return [Hash]        information of the stream if subcommand is `stream`
      # @return [Array<Hash>] information of the consumer groups if subcommand is `groups`
      # @return [Array<Hash>] information of the consumers if subcommand is `consumers`
      def xinfo(subcommand, key, group = nil)
        args = [:xinfo, subcommand, key, group].compact
        block = case subcommand.to_s.downcase
        when 'stream'              then Hashify
        when 'groups', 'consumers' then proc { |r| r.map(&Hashify) }
        end

        send_command(args, &block)
      end

      # Add new entry to the stream.
      #
      # @example Without options
      #   redis.xadd('mystream', f1: 'v1', f2: 'v2')
      # @example With options
      #   redis.xadd('mystream', { f1: 'v1', f2: 'v2' }, id: '0-0', maxlen: 1000, approximate: true, nomkstream: true)
      #
      # @param key   [String] the stream key
      # @param entry [Hash]   one or multiple field-value pairs
      # @param opts  [Hash]   several options for `XADD` command
      #
      # @option opts [String]  :id          the entry id, default value is `*`, it means auto generation
      # @option opts [Integer] :maxlen      max length of entries
      # @option opts [Boolean] :approximate whether to add `~` modifier of maxlen or not
      # @option opts [Boolean] :nomkstream  whether to add NOMKSTREAM, default is not to add
      #
      # @return [String] the entry id
      def xadd(key, entry, approximate: nil, maxlen: nil, nomkstream: nil, id: '*')
        args = [:xadd, key]
        args << 'NOMKSTREAM' if nomkstream
        if maxlen
          args << "MAXLEN"
          args << "~" if approximate
          args << maxlen
        end
        args << id
        args.concat(entry.flatten)
        send_command(args)
      end

      # Trims older entries of the stream if needed.
      #
      # @example Without options
      #   redis.xtrim('mystream', 1000)
      # @example With options
      #   redis.xtrim('mystream', 1000, approximate: true)
      # @example With strategy
      #   redis.xtrim('mystream', '1-0', strategy: 'MINID')
      #
      # @overload xtrim(key, maxlen, strategy: 'MAXLEN', approximate: true)
      #   @param key         [String]  the stream key
      #   @param maxlen      [Integer] max length of entries
      #   @param strategy    [String]  the limit strategy, must be MAXLEN
      #   @param approximate [Boolean] whether to add `~` modifier of maxlen or not
      #   @param limit       [Integer] maximum count of entries to be evicted
      # @overload xtrim(key, minid, strategy: 'MINID', approximate: true)
      #   @param key         [String]  the stream key
      #   @param minid       [String]  minimum id of entries
      #   @param strategy    [String]  the limit strategy, must be MINID
      #   @param approximate [Boolean] whether to add `~` modifier of minid or not
      #   @param limit       [Integer] maximum count of entries to be evicted
      #
      # @return [Integer] the number of entries actually deleted
      def xtrim(key, len_or_id, strategy: 'MAXLEN', approximate: false, limit: nil)
        strategy = strategy.to_s.upcase

        args = [:xtrim, key, strategy]
        args << '~' if approximate
        args << len_or_id
        args.concat(['LIMIT', limit]) if limit
        send_command(args)
      end

      # Delete entries by entry ids.
      #
      # @example With splatted entry ids
      #   redis.xdel('mystream', '0-1', '0-2')
      # @example With arrayed entry ids
      #   redis.xdel('mystream', ['0-1', '0-2'])
      #
      # @param key [String]        the stream key
      # @param ids [Array<String>] one or multiple entry ids
      #
      # @return [Integer] the number of entries actually deleted
      def xdel(key, *ids)
        args = [:xdel, key].concat(ids.flatten)
        send_command(args)
      end

      # Fetches entries of the stream in ascending order.
      #
      # @example Without options
      #   redis.xrange('mystream')
      # @example With a specific start
      #   redis.xrange('mystream', '0-1')
      # @example With a specific start and end
      #   redis.xrange('mystream', '0-1', '0-3')
      # @example With count options
      #   redis.xrange('mystream', count: 10)
      #
      # @param key [String]  the stream key
      # @param start [String]  first entry id of range, default value is `-`
      # @param end [String]  last entry id of range, default value is `+`
      # @param count [Integer] the number of entries as limit
      #
      # @return [Array<Array<String, Hash>>] the ids and entries pairs
      def xrange(key, start = '-', range_end = '+', count: nil)
        args = [:xrange, key, start, range_end]
        args.concat(['COUNT', count]) if count
        send_command(args, &HashifyStreamEntries)
      end

      # Fetches entries of the stream in descending order.
      #
      # @example Without options
      #   redis.xrevrange('mystream')
      # @example With a specific end
      #   redis.xrevrange('mystream', '0-3')
      # @example With a specific end and start
      #   redis.xrevrange('mystream', '0-3', '0-1')
      # @example With count options
      #   redis.xrevrange('mystream', count: 10)
      #
      # @param key [String]  the stream key
      # @param end [String]  first entry id of range, default value is `+`
      # @param start [String]  last entry id of range, default value is `-`
      # @params count [Integer] the number of entries as limit
      #
      # @return [Array<Array<String, Hash>>] the ids and entries pairs
      def xrevrange(key, range_end = '+', start = '-', count: nil)
        args = [:xrevrange, key, range_end, start]
        args.concat(['COUNT', count]) if count
        send_command(args, &HashifyStreamEntries)
      end

      # Returns the number of entries inside a stream.
      #
      # @example With key
      #   redis.xlen('mystream')
      #
      # @param key [String] the stream key
      #
      # @return [Integer] the number of entries
      def xlen(key)
        send_command([:xlen, key])
      end

      # Fetches entries from one or multiple streams. Optionally blocking.
      #
      # @example With a key
      #   redis.xread('mystream', '0-0')
      # @example With multiple keys
      #   redis.xread(%w[mystream1 mystream2], %w[0-0 0-0])
      # @example With count option
      #   redis.xread('mystream', '0-0', count: 2)
      # @example With block option
      #   redis.xread('mystream', '$', block: 1000)
      #
      # @param keys  [Array<String>] one or multiple stream keys
      # @param ids   [Array<String>] one or multiple entry ids
      # @param count [Integer]       the number of entries as limit per stream
      # @param block [Integer]       the number of milliseconds as blocking timeout
      #
      # @return [Hash{String => Hash{String => Hash}}] the entries
      def xread(keys, ids, count: nil, block: nil)
        args = [:xread]
        args << 'COUNT' << count if count
        args << 'BLOCK' << block.to_i if block
        _xread(args, keys, ids, block)
      end

      # Manages the consumer group of the stream.
      #
      # @example With `create` subcommand
      #   redis.xgroup(:create, 'mystream', 'mygroup', '$')
      # @example With `setid` subcommand
      #   redis.xgroup(:setid, 'mystream', 'mygroup', '$')
      # @example With `destroy` subcommand
      #   redis.xgroup(:destroy, 'mystream', 'mygroup')
      # @example With `delconsumer` subcommand
      #   redis.xgroup(:delconsumer, 'mystream', 'mygroup', 'consumer1')
      #
      # @param subcommand     [String] `create` `setid` `destroy` `delconsumer`
      # @param key            [String] the stream key
      # @param group          [String] the consumer group name
      # @param id_or_consumer [String]
      #   * the entry id or `$`, required if subcommand is `create` or `setid`
      #   * the consumer name, required if subcommand is `delconsumer`
      # @param mkstream [Boolean] whether to create an empty stream automatically or not
      #
      # @return [String] `OK` if subcommand is `create` or `setid`
      # @return [Integer] effected count if subcommand is `destroy` or `delconsumer`
      def xgroup(subcommand, key, group, id_or_consumer = nil, mkstream: false)
        args = [:xgroup, subcommand, key, group, id_or_consumer, (mkstream ? 'MKSTREAM' : nil)].compact
        send_command(args)
      end

      # Fetches a subset of the entries from one or multiple streams related with the consumer group.
      # Optionally blocking.
      #
      # @example With a key
      #   redis.xreadgroup('mygroup', 'consumer1', 'mystream', '>')
      # @example With multiple keys
      #   redis.xreadgroup('mygroup', 'consumer1', %w[mystream1 mystream2], %w[> >])
      # @example With count option
      #   redis.xreadgroup('mygroup', 'consumer1', 'mystream', '>', count: 2)
      # @example With block option
      #   redis.xreadgroup('mygroup', 'consumer1', 'mystream', '>', block: 1000)
      # @example With noack option
      #   redis.xreadgroup('mygroup', 'consumer1', 'mystream', '>', noack: true)
      #
      # @param group    [String]        the consumer group name
      # @param consumer [String]        the consumer name
      # @param keys     [Array<String>] one or multiple stream keys
      # @param ids      [Array<String>] one or multiple entry ids
      # @param opts     [Hash]          several options for `XREADGROUP` command
      #
      # @option opts [Integer] :count the number of entries as limit
      # @option opts [Integer] :block the number of milliseconds as blocking timeout
      # @option opts [Boolean] :noack whether message loss is acceptable or not
      #
      # @return [Hash{String => Hash{String => Hash}}] the entries
      def xreadgroup(group, consumer, keys, ids, count: nil, block: nil, noack: nil)
        args = [:xreadgroup, 'GROUP', group, consumer]
        args << 'COUNT' << count if count
        args << 'BLOCK' << block.to_i if block
        args << 'NOACK' if noack
        _xread(args, keys, ids, block)
      end

      # Removes one or multiple entries from the pending entries list of a stream consumer group.
      #
      # @example With a entry id
      #   redis.xack('mystream', 'mygroup', '1526569495631-0')
      # @example With splatted entry ids
      #   redis.xack('mystream', 'mygroup', '0-1', '0-2')
      # @example With arrayed entry ids
      #   redis.xack('mystream', 'mygroup', %w[0-1 0-2])
      #
      # @param key   [String]        the stream key
      # @param group [String]        the consumer group name
      # @param ids   [Array<String>] one or multiple entry ids
      #
      # @return [Integer] the number of entries successfully acknowledged
      def xack(key, group, *ids)
        args = [:xack, key, group].concat(ids.flatten)
        send_command(args)
      end

      # Changes the ownership of a pending entry
      #
      # @example With splatted entry ids
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, '0-1', '0-2')
      # @example With arrayed entry ids
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2])
      # @example With idle option
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2], idle: 1000)
      # @example With time option
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2], time: 1542866959000)
      # @example With retrycount option
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2], retrycount: 10)
      # @example With force option
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2], force: true)
      # @example With justid option
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, %w[0-1 0-2], justid: true)
      #
      # @param key           [String]        the stream key
      # @param group         [String]        the consumer group name
      # @param consumer      [String]        the consumer name
      # @param min_idle_time [Integer]       the number of milliseconds
      # @param ids           [Array<String>] one or multiple entry ids
      # @param opts          [Hash]          several options for `XCLAIM` command
      #
      # @option opts [Integer] :idle       the number of milliseconds as last time it was delivered of the entry
      # @option opts [Integer] :time       the number of milliseconds as a specific Unix Epoch time
      # @option opts [Integer] :retrycount the number of retry counter
      # @option opts [Boolean] :force      whether to create the pending entry to the pending entries list or not
      # @option opts [Boolean] :justid     whether to fetch just an array of entry ids or not
      #
      # @return [Hash{String => Hash}] the entries successfully claimed
      # @return [Array<String>]        the entry ids successfully claimed if justid option is `true`
      def xclaim(key, group, consumer, min_idle_time, *ids, **opts)
        args = [:xclaim, key, group, consumer, min_idle_time].concat(ids.flatten)
        args.concat(['IDLE',       opts[:idle].to_i])  if opts[:idle]
        args.concat(['TIME',       opts[:time].to_i])  if opts[:time]
        args.concat(['RETRYCOUNT', opts[:retrycount]]) if opts[:retrycount]
        args << 'FORCE'                                if opts[:force]
        args << 'JUSTID'                               if opts[:justid]
        blk = opts[:justid] ? Noop : HashifyStreamEntries
        send_command(args, &blk)
      end

      # Transfers ownership of pending stream entries that match the specified criteria.
      #
      # @example Claim next pending message stuck > 5 minutes  and mark as retry
      #   redis.xautoclaim('mystream', 'mygroup', 'consumer1', 3600000, '0-0')
      # @example Claim 50 next pending messages stuck > 5 minutes  and mark as retry
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, '0-0', count: 50)
      # @example Claim next pending message stuck > 5 minutes and don't mark as retry
      #   redis.xclaim('mystream', 'mygroup', 'consumer1', 3600000, '0-0', justid: true)
      # @example Claim next pending message after this id stuck > 5 minutes  and mark as retry
      #   redis.xautoclaim('mystream', 'mygroup', 'consumer1', 3600000, '1641321233-0')
      #
      # @param key           [String]        the stream key
      # @param group         [String]        the consumer group name
      # @param consumer      [String]        the consumer name
      # @param min_idle_time [Integer]       the number of milliseconds
      # @param start         [String]        entry id to start scanning from or 0-0 for everything
      # @param count         [Integer]       number of messages to claim (default 1)
      # @param justid        [Boolean]       whether to fetch just an array of entry ids or not.
      #                                      Does not increment retry count when true
      #
      # @return [Hash{String => Hash}] the entries successfully claimed
      # @return [Array<String>]        the entry ids successfully claimed if justid option is `true`
      def xautoclaim(key, group, consumer, min_idle_time, start, count: nil, justid: false)
        args = [:xautoclaim, key, group, consumer, min_idle_time, start]
        if count
          args << 'COUNT' << count.to_s
        end
        args << 'JUSTID' if justid
        blk = justid ? HashifyStreamAutoclaimJustId : HashifyStreamAutoclaim
        send_command(args, &blk)
      end

      # Fetches not acknowledging pending entries
      #
      # @example With key and group
      #   redis.xpending('mystream', 'mygroup')
      # @example With range options
      #   redis.xpending('mystream', 'mygroup', '-', '+', 10)
      # @example With range and idle time options
      #   redis.xpending('mystream', 'mygroup', '-', '+', 10, idle: 9000)
      # @example With range and consumer options
      #   redis.xpending('mystream', 'mygroup', '-', '+', 10, 'consumer1')
      #
      # @param key      [String]  the stream key
      # @param group    [String]  the consumer group name
      # @param start    [String]  start first entry id of range
      # @param end      [String]  end   last entry id of range
      # @param count    [Integer] count the number of entries as limit
      # @param consumer [String]  the consumer name
      #
      # @option opts [Integer] :idle       pending message minimum idle time in milliseconds
      #
      # @return [Hash]        the summary of pending entries
      # @return [Array<Hash>] the pending entries details if options were specified
      def xpending(key, group, *args, idle: nil)
        command_args = [:xpending, key, group]
        command_args << 'IDLE' << Integer(idle) if idle
        case args.size
        when 0, 3, 4
          command_args.concat(args)
        else
          raise ArgumentError, "wrong number of arguments (given #{args.size + 2}, expected 2, 5 or 6)"
        end

        summary_needed = args.empty?
        blk = summary_needed ? HashifyStreamPendings : HashifyStreamPendingDetails
        send_command(command_args, &blk)
      end

      private

      def _xread(args, keys, ids, blocking_timeout_msec)
        keys = keys.is_a?(Array) ? keys : [keys]
        ids = ids.is_a?(Array) ? ids : [ids]
        args << 'STREAMS'
        args.concat(keys)
        args.concat(ids)

        if blocking_timeout_msec.nil?
          send_command(args, &HashifyStreams)
        elsif blocking_timeout_msec.to_f.zero?
          send_blocking_command(args, 0, &HashifyStreams)
        else
          send_blocking_command(args, blocking_timeout_msec.to_f / 1_000, &HashifyStreams)
        end
      end
    end
  end
end
