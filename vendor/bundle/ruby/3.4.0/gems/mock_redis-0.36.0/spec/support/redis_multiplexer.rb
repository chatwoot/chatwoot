class BlankSlate
  instance_methods.each do |m|
    undef_method(m) unless m =~ /^__/ || %w[inspect object_id].include?(m.to_s)
  end
end

class RedisMultiplexer < BlankSlate
  MismatchedResponse = Class.new(StandardError)

  def initialize(*a)
    @mock_redis = MockRedis.new(*a)
    Redis.exists_returns_integer = true
    @real_redis = Redis.new(*a)
    _gsub_clear
  end

  def _gsub(from, to)
    @gsub_from = from
    @gsub_to = to
  end

  def _gsub_clear
    @gsub_from = @gsub_to = ''
  end

  ruby2_keywords def method_missing(method, *args, &blk)
    # If we're in a Redis command that accepts a block, and we execute more
    # redis commands, ONLY execute them on the Redis implementation that the
    # block came from.
    # e.g. if a pipelined command is started on a MockRedis object, DON'T send
    # commands inside the pipelined block to the real Redis object, as that one
    # WON'T be inside a pipelined command, and we'll see weird behaviour
    if blk
      @in_mock_block  = false
      @in_redis_block = true
    end
    real_retval, real_error =
      catch_errors { @in_mock_block ? :no_op : @real_redis.send(method, *args, &blk) }

    if blk
      @in_mock_block  = true
      @in_redis_block = false
    end
    mock_retval, mock_error =
      catch_errors { @in_redis_block ? :no_op : @mock_redis.send(method, *args, &blk) }

    if blk
      @in_mock_block  = false
      @in_redis_block = false
    end

    if mock_retval == :no_op || real_retval == :no_op
      # ignore, we were inside a block (like pipelined)
    elsif !equalish?(mock_retval, real_retval) && !mock_error && !real_error
      # no exceptions, just different behavior
      raise MismatchedResponse,
        "Mock failure: responses not equal.\n" \
        "Redis.#{method}(#{args.inspect}) returned #{real_retval.inspect}\n" \
        "MockRedis.#{method}(#{args.inspect}) returned #{mock_retval.inspect}\n"
    elsif !mock_error && real_error
      raise MismatchedResponse,
        "Mock failure: didn't raise an error when it should have.\n" \
        "Redis.#{method}(#{args.inspect}) raised #{real_error.inspect}\n" \
        "MockRedis.#{method}(#{args.inspect}) raised nothing " \
        "and returned #{mock_retval.inspect}"
    elsif !real_error && mock_error
      raise MismatchedResponse,
        "Mock failure: raised an error when it shouldn't have.\n" \
        "Redis.#{method}(#{args.inspect}) returned #{real_retval.inspect}\n" \
        "MockRedis.#{method}(#{args.inspect}) raised #{mock_error.inspect}"
    elsif mock_error && real_error && !equalish?(mock_error, real_error)
      raise MismatchedResponse,
        "Mock failure: raised the wrong error.\n" \
        "Redis.#{method}(#{args.inspect}) raised #{real_error.inspect}\n" \
        "MockRedis.#{method}(#{args.inspect}) raised #{mock_error.inspect}"
    end

    raise mock_error if mock_error
    mock_retval
  end

  def equalish?(a, b)
    if a == b
      true
    elsif a.is_a?(String) && b.is_a?(String)
      masked(a) == masked(b)
    elsif a.is_a?(Array) && b.is_a?(Array)
      a.collect { |c| masked(c.to_s) }.sort == b.collect { |c| masked(c.to_s) }.sort
    elsif a.is_a?(Exception) && b.is_a?(Exception)
      a.class == b.class && a.message == b.message
    elsif a.is_a?(Float) && b.is_a?(Float)
      delta = [a.abs, b.abs].min / 1_000_000.0
      (a - b).abs < delta
    else
      false
    end
  end

  def masked(str)
    str.gsub(@gsub_from, @gsub_to)
  end

  def mock
    @mock_redis
  end

  def real
    @real_redis
  end

  # Used in cleanup before() blocks.
  def send_without_checking(method, *args)
    @mock_redis.send(method, *args)
    @real_redis.send(method, *args)
  end

  def catch_errors
    retval = yield
    [retval, nil]
  rescue StandardError => e
    [nil, e]
  end
end
