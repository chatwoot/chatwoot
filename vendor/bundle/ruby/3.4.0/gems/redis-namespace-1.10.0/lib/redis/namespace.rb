require 'redis'
require 'redis/namespace/version'

class Redis
  class Namespace
    # The following tables define how input parameters and result
    # values should be modified for the namespace.
    #
    # COMMANDS is a hash. Each key is the name of a command and each
    # value is a two element array.
    #
    # The first element in the value array describes how to modify the
    # arguments passed. It can be one of:
    #
    #   nil
    #     Do nothing.
    #   :first
    #     Add the namespace to the first argument passed, e.g.
    #       GET key => GET namespace:key
    #   :all
    #     Add the namespace to all arguments passed, e.g.
    #       MGET key1 key2 => MGET namespace:key1 namespace:key2
    #   :exclude_first
    #     Add the namespace to all arguments but the first, e.g.
    #   :exclude_last
    #     Add the namespace to all arguments but the last, e.g.
    #       BLPOP key1 key2 timeout =>
    #       BLPOP namespace:key1 namespace:key2 timeout
    #   :exclude_options
    #     Add the namespace to all arguments, except the last argument,
    #     if the last argument is a hash of options.
    #       ZUNIONSTORE key1 2 key2 key3 WEIGHTS 2 1 =>
    #       ZUNIONSTORE namespace:key1 2 namespace:key2 namespace:key3 WEIGHTS 2 1
    #   :alternate
    #     Add the namespace to every other argument, e.g.
    #       MSET key1 value1 key2 value2 =>
    #       MSET namespace:key1 value1 namespace:key2 value2
    #   :sort
    #     Add namespace to first argument if it is non-nil
    #     Add namespace to second arg's :by and :store if second arg is a Hash
    #     Add namespace to each element in second arg's :get if second arg is
    #       a Hash; forces second arg's :get to be an Array if present.
    #   :eval_style
    #     Add namespace to each element in keys argument (via options hash or multi-args)
    #   :scan_style
    #     Add namespace to :match option, or supplies "#{namespace}:*" if not present.
    #
    # The second element in the value array describes how to modify
    # the return value of the Redis call. It can be one of:
    #
    #   nil
    #     Do nothing.
    #   :all
    #     Add the namespace to all elements returned, e.g.
    #       key1 key2 => namespace:key1 namespace:key2
    NAMESPACED_COMMANDS = {
      "append"           => [ :first ],
      "bitcount"         => [ :first ],
      "bitop"            => [ :exclude_first ],
      "bitpos"           => [ :first ],
      "blpop"            => [ :exclude_last, :first ],
      "brpop"            => [ :exclude_last, :first ],
      "brpoplpush"       => [ :exclude_last ],
      "bzpopmin"         => [ :first ],
      "bzpopmax"         => [ :first ],
      "debug"            => [ :exclude_first ],
      "decr"             => [ :first ],
      "decrby"           => [ :first ],
      "del"              => [ :all   ],
      "dump"             => [ :first ],
      "exists"           => [ :all ],
      "exists?"          => [ :all ],
      "expire"           => [ :first ],
      "expireat"         => [ :first ],
      "eval"             => [ :eval_style ],
      "evalsha"          => [ :eval_style ],
      "get"              => [ :first ],
      "getex"            => [ :first ],
      "getbit"           => [ :first ],
      "getrange"         => [ :first ],
      "getset"           => [ :first ],
      "hset"             => [ :first ],
      "hsetnx"           => [ :first ],
      "hget"             => [ :first ],
      "hincrby"          => [ :first ],
      "hincrbyfloat"     => [ :first ],
      "hmget"            => [ :first ],
      "hmset"            => [ :first ],
      "hdel"             => [ :first ],
      "hexists"          => [ :first ],
      "hlen"             => [ :first ],
      "hkeys"            => [ :first ],
      "hscan"            => [ :first ],
      "hscan_each"       => [ :first ],
      "hvals"            => [ :first ],
      "hgetall"          => [ :first ],
      "incr"             => [ :first ],
      "incrby"           => [ :first ],
      "incrbyfloat"      => [ :first ],
      "keys"             => [ :first, :all ],
      "lindex"           => [ :first ],
      "linsert"          => [ :first ],
      "llen"             => [ :first ],
      "lpop"             => [ :first ],
      "lpush"            => [ :first ],
      "lpushx"           => [ :first ],
      "lrange"           => [ :first ],
      "lrem"             => [ :first ],
      "lset"             => [ :first ],
      "ltrim"            => [ :first ],
      "mapped_hmset"     => [ :first ],
      "mapped_hmget"     => [ :first ],
      "mapped_mget"      => [ :all, :all ],
      "mapped_mset"      => [ :all ],
      "mapped_msetnx"    => [ :all ],
      "mget"             => [ :all ],
      "monitor"          => [ :monitor ],
      "move"             => [ :first ],
      "mset"             => [ :alternate ],
      "msetnx"           => [ :alternate ],
      "object"           => [ :exclude_first ],
      "persist"          => [ :first ],
      "pexpire"          => [ :first ],
      "pexpireat"        => [ :first ],
      "pfadd"            => [ :first ],
      "pfcount"          => [ :all ],
      "pfmerge"          => [ :all ],
      "psetex"           => [ :first ],
      "psubscribe"       => [ :all ],
      "pttl"             => [ :first ],
      "publish"          => [ :first ],
      "punsubscribe"     => [ :all ],
      "rename"           => [ :all ],
      "renamenx"         => [ :all ],
      "restore"          => [ :first ],
      "rpop"             => [ :first ],
      "rpoplpush"        => [ :all ],
      "rpush"            => [ :first ],
      "rpushx"           => [ :first ],
      "sadd"             => [ :first ],
      "sadd?"             => [ :first ],
      "scard"            => [ :first ],
      "scan"             => [ :scan_style, :second ],
      "scan_each"        => [ :scan_style, :all ],
      "sdiff"            => [ :all ],
      "sdiffstore"       => [ :all ],
      "set"              => [ :first ],
      "setbit"           => [ :first ],
      "setex"            => [ :first ],
      "setnx"            => [ :first ],
      "setrange"         => [ :first ],
      "sinter"           => [ :all ],
      "sinterstore"      => [ :all ],
      "sismember"        => [ :first ],
      "smembers"         => [ :first ],
      "smismember"       => [ :first ],
      "smove"            => [ :exclude_last ],
      "sort"             => [ :sort  ],
      "spop"             => [ :first ],
      "srandmember"      => [ :first ],
      "srem"             => [ :first ],
      "sscan"            => [ :first ],
      "sscan_each"       => [ :first ],
      "strlen"           => [ :first ],
      "subscribe"        => [ :all ],
      "sunion"           => [ :all ],
      "sunionstore"      => [ :all ],
      "ttl"              => [ :first ],
      "type"             => [ :first ],
      "unlink"           => [ :all   ],
      "unsubscribe"      => [ :all ],
      "zadd"             => [ :first ],
      "zcard"            => [ :first ],
      "zcount"           => [ :first ],
      "zincrby"          => [ :first ],
      "zinterstore"      => [ :exclude_options ],
      "zpopmin"          => [ :first ],
      "zpopmax"          => [ :first ],
      "zrange"           => [ :first ],
      "zrangebyscore"    => [ :first ],
      "zrangebylex"      => [ :first ],
      "zrank"            => [ :first ],
      "zrem"             => [ :first ],
      "zremrangebyrank"  => [ :first ],
      "zremrangebyscore" => [ :first ],
      "zremrangebylex"   => [ :first ],
      "zrevrange"        => [ :first ],
      "zrevrangebyscore" => [ :first ],
      "zrevrangebylex"   => [ :first ],
      "zrevrank"         => [ :first ],
      "zscan"            => [ :first ],
      "zscan_each"       => [ :first ],
      "zscore"           => [ :first ],
      "zunionstore"      => [ :exclude_options ]
    }
    TRANSACTION_COMMANDS = {
      "discard"          => [],
      "exec"             => [],
      "multi"            => [],
      "unwatch"          => [ :all ],
      "watch"            => [ :all ],
    }
    HELPER_COMMANDS = {
      "auth"             => [],
      "disconnect!"      => [],
      "close"            => [],
      "echo"             => [],
      "ping"             => [],
      "time"             => [],
    }
    ADMINISTRATIVE_COMMANDS = {
      "bgrewriteaof"     => [],
      "bgsave"           => [],
      "config"           => [],
      "dbsize"           => [],
      "flushall"         => [],
      "flushdb"          => [],
      "info"             => [],
      "lastsave"         => [],
      "quit"             => [],
      "randomkey"        => [],
      "save"             => [],
      "script"           => [],
      "select"           => [],
      "shutdown"         => [],
      "slaveof"          => [],
    }

    DEPRECATED_COMMANDS = [
      ADMINISTRATIVE_COMMANDS
    ].compact.reduce(:merge)

    COMMANDS = [
      NAMESPACED_COMMANDS,
      TRANSACTION_COMMANDS,
      HELPER_COMMANDS,
      ADMINISTRATIVE_COMMANDS,
    ].compact.reduce(:merge)

    # Support 1.8.7 by providing a namespaced reference to Enumerable::Enumerator
    Enumerator = Enumerable::Enumerator unless defined?(::Enumerator)

    # This is used by the Redis gem to determine whether or not to display that deprecation message.
    @sadd_returns_boolean = true

    class << self
      attr_accessor :sadd_returns_boolean
    end

    attr_writer :namespace
    attr_reader :redis
    attr_accessor :warning

    def initialize(namespace, options = {})
      @namespace = namespace
      @redis = options[:redis] || Redis.new
      @warning = !!options.fetch(:warning) do
                   !ENV['REDIS_NAMESPACE_QUIET']
                 end
      @deprecations = !!options.fetch(:deprecations) do
                        ENV['REDIS_NAMESPACE_DEPRECATIONS']
                      end
      @has_new_client_method = @redis.respond_to?(:_client)
    end

    def deprecations?
      @deprecations
    end

    def warning?
      @warning
    end

    def client
      warn("The client method is deprecated as of redis-rb 4.0.0, please use the new _client " +
            "method instead. Support for the old method will be removed in redis-namespace 2.0.") if @has_new_client_method && deprecations?
      _client
    end

    def _client
      @has_new_client_method ? @redis._client : @redis.client # for redis-4.0.0
    end

    # Ruby defines a now deprecated type method so we need to override it here
    # since it will never hit method_missing
    def type(key)
      call_with_namespace(:type, key)
    end

    alias_method :self_respond_to?, :respond_to?

    # emulate Ruby 1.9+ and keep respond_to_missing? logic together.
    def respond_to?(command, include_private=false)
      return !deprecations? if DEPRECATED_COMMANDS.include?(command.to_s.downcase)

      respond_to_missing?(command, include_private) or super
    end

    def keys(query = nil)
      call_with_namespace(:keys, query || '*')
    end

    def multi(&block)
      if block_given?
        namespaced_block(:multi, &block)
      else
        call_with_namespace(:multi)
      end
    end

    def pipelined(&block)
      namespaced_block(:pipelined, &block)
    end

    def namespace(desired_namespace = nil)
      if desired_namespace
        yield Redis::Namespace.new(desired_namespace,
                                   :redis => @redis)
      end

      @namespace.respond_to?(:call) ? @namespace.call : @namespace
    end

    def full_namespace
      redis.is_a?(Namespace) ? "#{redis.full_namespace}:#{namespace}" : namespace.to_s
    end

    def connection
      @redis.connection.tap { |info| info[:namespace] = namespace }
    end

    def exec
      call_with_namespace(:exec)
    end

    def eval(*args)
      call_with_namespace(:eval, *args)
    end
    ruby2_keywords(:eval) if respond_to?(:ruby2_keywords, true)

    # This operation can run for a very long time if the namespace contains lots of keys!
    # It should be used in tests, or when the namespace is small enough
    # and you are sure you know what you are doing.
    def clear
      if warning?
        warn("This operation can run for a very long time if the namespace contains lots of keys! " +
             "It should be used in tests, or when the namespace is small enough " +
             "and you are sure you know what you are doing.")
      end

      batch_size = 1000

      if supports_scan?
        cursor = "0"
        begin
          cursor, keys = scan(cursor, count: batch_size)
          del(*keys) unless keys.empty?
        end until cursor == "0"
      else
        all_keys = keys("*")
        all_keys.each_slice(batch_size) do |keys|
          del(*keys)
        end
      end
    end

    ADMINISTRATIVE_COMMANDS.keys.each do |command|
      define_method(command) do |*args, &block|
        raise NoMethodError if deprecations?

        if warning?
          warn("Passing '#{command}' command to redis as is; " +
               "administrative commands cannot be effectively namespaced " +
               "and should be called on the redis connection directly; " +
               "passthrough has been deprecated and will be removed in " +
               "redis-namespace 2.0 (at #{call_site})"
               )
        end
        call_with_namespace(command, *args, &block)
      end
      ruby2_keywords(command) if respond_to?(:ruby2_keywords, true)
    end

    COMMANDS.keys.each do |command|
      next if ADMINISTRATIVE_COMMANDS.include?(command)
      next if method_defined?(command)

      define_method(command) do |*args, &block|
        call_with_namespace(command, *args, &block)
      end
      ruby2_keywords(command) if respond_to?(:ruby2_keywords, true)
    end

    def method_missing(command, *args, &block)
      normalized_command = command.to_s.downcase

      if COMMANDS.include?(normalized_command)
        send(normalized_command, *args, &block)
      elsif @redis.respond_to?(normalized_command) && !deprecations?
        # blind passthrough is deprecated and will be removed in 2.0
        # redis-namespace does not know how to handle this command.
        # Passing it to @redis as is, where redis-namespace shows
        # a warning message if @warning is set.
        if warning?
          warn("Passing '#{command}' command to redis as is; blind " +
               "passthrough has been deprecated and will be removed in " +
               "redis-namespace 2.0 (at #{call_site})")
        end

        wrapped_send(@redis, command, args, &block)
      else
        super
      end
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

    def inspect
      "<#{self.class.name} v#{VERSION} with client v#{Redis::VERSION} "\
      "for #{@redis.id}/#{full_namespace}>"
    end

    def respond_to_missing?(command, include_all=false)
      normalized_command = command.to_s.downcase

      case
      when COMMANDS.include?(normalized_command)
        true
      when !deprecations? && redis.respond_to?(command, include_all)
        true
      else
        defined?(super) && super
      end
    end

    def call_with_namespace(command, *args, &block)
      handling = COMMANDS[command.to_s.downcase]

      if handling.nil?
        fail("Redis::Namespace does not know how to handle '#{command}'.")
      end

      (before, after) = handling

      # Modify the local *args array in-place, no need to copy it.
      args.map! {|arg| clone_args(arg)}

      # Add the namespace to any parameters that are keys.
      case before
      when :first
        args[0] = add_namespace(args[0]) if args[0]
        args[-1] = ruby2_keywords_hash(args[-1]) if args[-1].is_a?(Hash)
      when :all
        args = add_namespace(args)
      when :exclude_first
        first = args.shift
        args = add_namespace(args)
        args.unshift(first) if first
      when :exclude_last
        last = args.pop unless args.length == 1
        args = add_namespace(args)
        args.push(last) if last
      when :exclude_options
        if args.last.is_a?(Hash)
          last = ruby2_keywords_hash(args.pop)
          args = add_namespace(args)
          args.push(last)
        else
          args = add_namespace(args)
        end
      when :alternate
        args = args.flatten
        args.each_with_index { |a, i| args[i] = add_namespace(a) if i.even? }
      when :sort
        args[0] = add_namespace(args[0]) if args[0]
        if args[1].is_a?(Hash)
          [:by, :store].each do |key|
            args[1][key] = add_namespace(args[1][key]) if args[1][key]
          end

          args[1][:get] = Array(args[1][:get])

          args[1][:get].each_index do |i|
            args[1][:get][i] = add_namespace(args[1][:get][i]) unless args[1][:get][i] == "#"
          end
          args[1] = ruby2_keywords_hash(args[1])
        end
      when :eval_style
        # redis.eval() and evalsha() can either take the form:
        #
        #   redis.eval(script, [key1, key2], [argv1, argv2])
        #
        # Or:
        #
        #   redis.eval(script, :keys => ['k1', 'k2'], :argv => ['arg1', 'arg2'])
        #
        # This is a tricky + annoying special case, where we only want the `keys`
        # argument to be namespaced.
        if args.last.is_a?(Hash)
          args.last[:keys] = add_namespace(args.last[:keys])
        else
          args[1] = add_namespace(args[1])
        end
      when :scan_style
        options = (args.last.kind_of?(Hash) ? args.pop : {})
        options[:match] = add_namespace(options.fetch(:match, '*'))
        args << ruby2_keywords_hash(options)

        if block
          original_block = block
          block = proc { |key| original_block.call rem_namespace(key) }
        end
      end

      # Dispatch the command to Redis and store the result.
      result = wrapped_send(@redis, command, args, &block)

      # Don't try to remove namespace from a Redis::Future, you can't.
      return result if result.is_a?(Redis::Future)

      # Remove the namespace from results that are keys.
      case after
      when :all
        result = rem_namespace(result)
      when :first
        result[0] = rem_namespace(result[0]) if result
      when :second
        result[1] = rem_namespace(result[1]) if result
      end

      result
    end
    ruby2_keywords(:call_with_namespace) if respond_to?(:ruby2_keywords, true)

  protected

    def redis=(redis)
      @redis = redis
    end

  private

    if Hash.respond_to?(:ruby2_keywords_hash)
      def ruby2_keywords_hash(kwargs)
        Hash.ruby2_keywords_hash(kwargs)
      end
    else
      def ruby2_keywords_hash(kwargs)
        kwargs
      end
    end

    def wrapped_send(redis_client, command, args = [], &block)
      if redis_client.class.name == "ConnectionPool"
        redis_client.with do |pool_connection|
          pool_connection.send(command, *args, &block)
        end
      else
        redis_client.send(command, *args, &block)
      end
    end

    # Avoid modifying the caller's (pass-by-reference) arguments.
    def clone_args(arg)
      if arg.is_a?(Array)
        arg.map {|sub_arg| clone_args(sub_arg)}
      elsif arg.is_a?(Hash)
        Hash[arg.map {|k, v| [clone_args(k), clone_args(v)]}]
      else
        arg # Some objects (e.g. symbol) can't be dup'd.
      end
    end

    def call_site
      caller.reject { |l| l.start_with?(__FILE__) }.first
    end

    def namespaced_block(command, &block)
      if block.arity == 0
        wrapped_send(redis, command, &block)
      else
        outer_block = proc { |r| copy = dup; copy.redis = r; yield copy }
        wrapped_send(redis, command, &outer_block)
      end
    end

    def add_namespace(key)
      return key unless key && namespace

      case key
      when Array
        key.map! {|k| add_namespace k}
      when Hash
        key.keys.each {|k| key[add_namespace(k)] = key.delete(k)}
        key
      else
        "#{namespace}:#{key}"
      end
    end

    def rem_namespace(key)
      return key unless key && namespace

      case key
      when Array
        key.map {|k| rem_namespace k}
      when Hash
        Hash[*key.map {|k, v| [ rem_namespace(k), v ]}.flatten]
      when Enumerator
        create_enumerator do |yielder|
          key.each { |k| yielder.yield rem_namespace(k) }
        end
      else
        key.to_s.sub(/\A#{namespace}:/, '')
      end
    end

    def create_enumerator(&block)
      # Enumerator in 1.8.7 *requires* a single argument, so we need to use
      # its Generator class, which matches the block syntax of 1.9.x's
      # Enumerator class.
      if RUBY_VERSION.start_with?('1.8')
        require 'generator' unless defined?(Generator)
        Generator.new(&block).to_enum
      else
        Enumerator.new(&block)
      end
    end

    def supports_scan?
      redis_version = @redis.info["redis_version"]
      Gem::Version.new(redis_version) >= Gem::Version.new("2.8.0")
    end
  end
end
