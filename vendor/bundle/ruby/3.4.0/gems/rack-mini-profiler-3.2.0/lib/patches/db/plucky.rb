# frozen_string_literal: true

# mongo_mapper patches
# TODO: Include overrides for distinct, update, cursor, and create
class Plucky::Query
  alias_method :find_each_without_profiling, :find_each
  alias_method :find_one_without_profiling, :find_one
  alias_method :count_without_profiling, :count
  alias_method :remove_without_profiling, :remove

  def find_each(*args, &blk)
    profile_database_operation(__callee__, filtered_inspect(), *args, &blk)
  end

  def find_one(*args, &blk)
    profile_database_operation(__callee__, filtered_inspect(args[0]), *args, &blk)
  end

  def count(*args, &blk)
    profile_database_operation(__callee__, filtered_inspect(), *args, &blk)
  end

  def remove(*args, &blk)
    profile_database_operation(__callee__, filtered_inspect(), *args, &blk)
  end

  private

  def profile_database_operation(method, message, *args, &blk)
    return self.send("#{method.id2name}_without_profiling", *args, &blk) unless SqlPatches.should_measure?

    start        = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result       = self.send("#{method.id2name}_without_profiling", *args, &blk)
    elapsed_time = SqlPatches.elapsed_time(start)

    query_message = "#{@collection.name}.#{method.id2name} => #{message}"
    ::Rack::MiniProfiler.record_sql(query_message, elapsed_time)

    result
  end

  def filtered_inspect(hash = to_hash())
    hash_string = hash.reject { |key| key == :transformer }.collect do |key, value|
      "  #{key}: #{value.inspect}"
    end.join(",\n")

    "{\n#{hash_string}\n}"
  end
end
