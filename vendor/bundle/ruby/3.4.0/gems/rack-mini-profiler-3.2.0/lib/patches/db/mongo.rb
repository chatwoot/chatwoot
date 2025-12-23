# frozen_string_literal: true

# Mongo/Mongoid 5 patches
class Mongo::Server::Connection
  def dispatch_with_timing(*args, &blk)
    return dispatch_without_timing(*args, &blk) unless SqlPatches.should_measure?

    result, _record = SqlPatches.record_sql(args[0][0].payload.inspect) do
      dispatch_without_timing(*args, &blk)
    end
    result
  end

  # TODO: change to Module#prepend as soon as Ruby 1.9.3 support is dropped
  alias_method :dispatch_without_timing, :dispatch
  alias_method :dispatch, :dispatch_with_timing

end
