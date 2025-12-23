# frozen_string_literal: true

require "json"

module SimpleCov
  #
  # Singleton that is responsible for caching, loading and merging
  # SimpleCov::Results into a single result for coverage analysis based
  # upon multiple test suites.
  #
  module ResultMerger
    class << self
      # The path to the .resultset.json cache file
      def resultset_path
        File.join(SimpleCov.coverage_path, ".resultset.json")
      end

      def resultset_writelock
        File.join(SimpleCov.coverage_path, ".resultset.json.lock")
      end

      def merge_and_store(*file_paths, ignore_timeout: false)
        result = merge_results(*file_paths, ignore_timeout: ignore_timeout)
        store_result(result) if result
        result
      end

      def merge_results(*file_paths, ignore_timeout: false)
        # It is intentional here that files are only read in and parsed one at a time.
        #
        # In big CI setups you might deal with 100s of CI jobs and each one producing Megabytes
        # of data. Reading them all in easily produces Gigabytes of memory consumption which
        # we want to avoid.
        #
        # For similar reasons a SimpleCov::Result is only created in the end as that'd create
        # even more data especially when it also reads in all source files.
        initial_memo = valid_results(file_paths.shift, ignore_timeout: ignore_timeout)

        command_names, coverage = file_paths.reduce(initial_memo) do |memo, file_path|
          merge_coverage(memo, valid_results(file_path, ignore_timeout: ignore_timeout))
        end

        create_result(command_names, coverage)
      end

      def valid_results(file_path, ignore_timeout: false)
        results = parse_file(file_path)
        merge_valid_results(results, ignore_timeout: ignore_timeout)
      end

      def parse_file(path)
        data = read_file(path)
        parse_json(data)
      end

      def read_file(path)
        return unless File.exist?(path)

        data = File.read(path)
        return if data.nil? || data.length < 2

        data
      end

      def parse_json(content)
        return {} unless content

        JSON.parse(content) || {}
      rescue StandardError
        warn "[SimpleCov]: Warning! Parsing JSON content of resultset file failed"
        {}
      end

      def merge_valid_results(results, ignore_timeout: false)
        results = results.select { |_command_name, data| within_merge_timeout?(data) } unless ignore_timeout

        command_plus_coverage = results.map do |command_name, data|
          [[command_name], adapt_result(data.fetch("coverage"))]
        end

        # one file itself _might_ include multiple test runs
        merge_coverage(*command_plus_coverage)
      end

      def within_merge_timeout?(data)
        time_since_result_creation(data) < SimpleCov.merge_timeout
      end

      def time_since_result_creation(data)
        Time.now - Time.at(data.fetch("timestamp"))
      end

      def create_result(command_names, coverage)
        return nil unless coverage

        command_name = command_names.reject(&:empty?).sort.join(", ")
        SimpleCov::Result.new(coverage, command_name: command_name)
      end

      def merge_coverage(*results)
        return [[""], nil] if results.empty?
        return results.first if results.size == 1

        results.reduce do |(memo_command, memo_coverage), (command, coverage)|
          # timestamp is dropped here, which is intentional (we merge it, it gets a new time stamp as of now)
          merged_coverage = Combine.combine(Combine::ResultsCombiner, memo_coverage, coverage)
          merged_command = memo_command + command

          [merged_command, merged_coverage]
        end
      end

      #
      # Gets all SimpleCov::Results stored in resultset, merges them and produces a new
      # SimpleCov::Result with merged coverage data and the command_name
      # for the result consisting of a join on all source result's names
      def merged_result
        # conceptually this is just doing `merge_results(resultset_path)`
        # it's more involved to make syre `synchronize_resultset` is only used around reading
        resultset_hash = read_resultset
        command_names, coverage = merge_valid_results(resultset_hash)

        create_result(command_names, coverage)
      end

      def read_resultset
        resultset_content =
          synchronize_resultset do
            read_file(resultset_path)
          end

        parse_json(resultset_content)
      end

      # Saves the given SimpleCov::Result in the resultset cache
      def store_result(result)
        synchronize_resultset do
          # Ensure we have the latest, in case it was already cached
          new_resultset = read_resultset

          # A single result only ever has one command_name, see `SimpleCov::Result#to_hash`
          command_name, data = result.to_hash.first
          new_resultset[command_name] = data
          File.open(resultset_path, "w+") do |f_|
            f_.puts JSON.pretty_generate(new_resultset)
          end
        end
        true
      end

      # Ensure only one process is reading or writing the resultset at any
      # given time
      def synchronize_resultset
        # make it reentrant
        return yield if defined?(@resultset_locked) && @resultset_locked

        begin
          @resultset_locked = true
          File.open(resultset_writelock, "w+") do |f|
            f.flock(File::LOCK_EX)
            yield
          end
        ensure
          @resultset_locked = false
        end
      end

      # We changed the format of the raw result data in simplecov, as people are likely
      # to have "old" resultsets lying around (but not too old so that they're still
      # considered we can adapt them).
      # See https://github.com/simplecov-ruby/simplecov/pull/824#issuecomment-576049747
      def adapt_result(result)
        if pre_simplecov_0_18_result?(result)
          adapt_pre_simplecov_0_18_result(result)
        else
          result
        end
      end

      # pre 0.18 coverage data pointed from file directly to an array of line coverage
      def pre_simplecov_0_18_result?(result)
        _key, data = result.first

        data.is_a?(Array)
      end

      def adapt_pre_simplecov_0_18_result(result)
        result.transform_values do |line_coverage_data|
          {"lines" => line_coverage_data}
        end
      end
    end
  end
end
