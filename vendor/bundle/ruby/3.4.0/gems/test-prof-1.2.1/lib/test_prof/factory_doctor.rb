# frozen_string_literal: true

require "test_prof/factory_bot"
require "test_prof/factory_doctor/factory_bot_patch"
require "test_prof/factory_doctor/fabrication_patch"

module TestProf
  # FactoryDoctor is a tool that helps you identify
  # tests that perform unnecessary database queries.
  module FactoryDoctor
    class Result # :nodoc:
      attr_reader :count, :time, :queries_count

      def initialize(count, time, queries_count)
        @count = count
        @time = time
        @queries_count = queries_count
      end

      def bad?
        count > 0 && queries_count.zero? && time >= FactoryDoctor.config.threshold
      end
    end

    IGNORED_QUERIES_PATTERN = %r{(
      pg_table|
      pg_attribute|
      pg_namespace|
      show\stables|
      pragma|
      sqlite_master/rollback|
      \ATRUNCATE TABLE|
      \AALTER TABLE|
      \ABEGIN|
      \ACOMMIT|
      \AROLLBACK|
      \ARELEASE|
      \ASAVEPOINT
    )}xi.freeze

    class Configuration
      attr_accessor :event, :threshold

      def initialize
        # event to track for DB interactions
        @event = ENV.fetch("FDOC_EVENT", "sql.active_record")
        # consider result good if time wasted less then threshold
        @threshold = ENV.fetch("FDOC_THRESHOLD", "0.01").to_f
      end
    end

    class << self
      include TestProf::Logging

      attr_reader :count, :time, :queries_count

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # Patch factory lib, init counters
      def init
        reset!

        @running = false

        log :info, "FactoryDoctor enabled (event: \"#{config.event}\", threshold: #{config.threshold})"

        # Monkey-patch FactoryBot / FactoryGirl
        TestProf::FactoryBot::FactoryRunner.prepend(FactoryBotPatch) if
          defined?(TestProf::FactoryBot)

        # Monkey-patch Fabrication
        ::Fabricate.singleton_class.prepend(FabricationPatch) if
          defined?(::Fabricate)

        subscribe!

        @stamp = ENV["FDOC_STAMP"]

        RSpecStamp.config.tags = @stamp if stamp?
      end

      def stamp?
        !@stamp.nil?
      end

      def start
        reset!
        @running = true
      end

      def stop
        @running = false
      end

      def result
        Result.new(count, time, queries_count)
      end

      # Do not analyze code within the block
      def ignore
        @ignored = true
        res = yield
      ensure
        @ignored = false
        res
      end

      def ignore!
        @ignored = true
      end

      def ignore?
        @ignored == true
      end

      def within_factory(strategy)
        return yield if ignore? || !running? || (strategy != :create)

        begin
          ts = TestProf.now if @depth.zero?
          @depth += 1
          @count += 1
          yield
        ensure
          @depth -= 1

          @time += (TestProf.now - ts) if @depth.zero?
        end
      end

      private

      def reset!
        @depth = 0
        @time = 0.0
        @count = 0
        @queries_count = 0
        @ignored = false
      end

      def subscribe!
        ::ActiveSupport::Notifications.subscribe(config.event) do |_name, _start, _finish, _id, query|
          next if ignore? || !running? || within_factory?
          next if IGNORED_QUERIES_PATTERN.match?(query[:sql])
          @queries_count += 1
        end
      end

      def within_factory?
        @depth > 0
      end

      def running?
        @running == true
      end
    end
  end
end

require "test_prof/factory_doctor/rspec" if TestProf.rspec?
require "test_prof/factory_doctor/minitest" if TestProf.minitest?
