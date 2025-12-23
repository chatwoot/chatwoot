# frozen_string_literal: true

require "test_prof"
require "test_prof/factory_bot"
require "test_prof/factory_default/factory_bot_patch"
require "test_prof/ext/float_duration"
require "test_prof/ext/active_record_refind" if defined?(::ActiveRecord::Base)

module TestProf
  # FactoryDefault allows use to re-use associated objects
  # in factories implicilty
  module FactoryDefault
    using FloatDuration
    using Ext::ActiveRecordRefind if defined?(::ActiveRecord::Base)

    using(Module.new do
      refine Object do
        def to_override_key
          "<#{self.class.name}::$id$#{object_id}$di$>"
        end

        def refind
          self
        end
      end

      if defined?(::ActiveRecord::Base)
        refine ::ActiveRecord::Base do
          def to_override_key
            "<#{self.class.name}\#$id$#{public_send(self.class.primary_key)}$di$>"
          end
        end
      end

      [
        String,
        Integer,
        Float,
        FalseClass,
        TrueClass,
        NilClass,
        Regexp
      ].each do |mod|
        refine(mod) do
          def to_override_key
            inspect
          end
        end
      end
    end)

    class Profiler
      include Logging

      attr_reader :data

      def initialize
        @data = Hash.new { |h, k| h[k] = {count: 0, time: 0.0} }
      end

      def instrument(name, traits, overrides)
        start = TestProf.now
        yield.tap do
          time = TestProf.now - start
          key = build_association_name(name, traits, overrides)
          data[key][:count] += 1
          data[key][:time] += time
        end
      end

      def print_report
        if data.empty?
          log :info, "FactoryDefault profiler collected no data"
          return
        end

        # Merge object overrides into one stats record
        data = self.data.each_with_object({}) do |(name, stats), acc|
          name = name.gsub(/\$id\$.+\$di\$/, "<id>")
          if acc.key?(name)
            acc[name][:count] += stats[:count]
            acc[name][:time] += stats[:time]
          else
            acc[name] = stats
          end
        end

        msgs = []

        msgs <<
          <<~MSG
            Factory associations usage:
          MSG

        first_column = data.keys.map(&:size).max + 2

        msgs << format(
          "%#{first_column}s  %9s  %12s",
          "factory", "count", "total time"
        )

        msgs << ""

        total_count = 0
        total_time = 0.0

        data.to_a.sort_by { |(_, v)| -v[:time] }.each do |(key, factory_stats)|
          total_count += factory_stats[:count]
          total_time += factory_stats[:time]

          msgs << format(
            "%#{first_column}s  %9d  %12s",
            key, factory_stats[:count], factory_stats[:time].duration
          )
        end

        msgs <<
          <<~MSG

            Total associations created: #{total_count}
            Total uniq associations created: #{data.size}
            Total time spent: #{total_time.duration}

          MSG

        log :info, msgs.join("\n")
      end

      private

      def build_association_name(name, traits, overrides)
        traits_str = "[#{traits.join(",")}]" if traits&.any?
        overrides_str = "{#{overrides.map { |k, v| "#{k}:#{v.to_override_key}" }.join(",")}}" if overrides&.any?
        "#{name}#{traits_str}#{overrides_str}"
      end
    end

    class NoopProfiler
      def instrument(*)
        yield
      end

      def print_report
      end
    end

    module DefaultSyntax # :nodoc:
      def create_default(name, *args, &block)
        options = args.extract_options!
        default_options = {}
        default_options[:preserve_traits] = options.delete(:preserve_traits) if options.key?(:preserve_traits)
        default_options[:preserve_attributes] = options.delete(:preserve_attributes) if options.key?(:preserve_attributes)

        obj = TestProf::FactoryBot.create(name, *args, options, &block)

        # Factory with traits
        name = [name, *args] if args.any?

        set_factory_default(name, obj, **default_options)
      end

      def set_factory_default(name, obj, preserve_traits: FactoryDefault.config.preserve_traits, preserve_attributes: FactoryDefault.config.preserve_attributes, **other)
        FactoryDefault.register(
          name, obj,
          preserve_traits: preserve_traits,
          preserve_attributes: preserve_attributes,
          **other
        )
      end

      def skip_factory_default(&block)
        FactoryDefault.disable!(&block)
      end
    end

    class Configuration
      attr_accessor :preserve_traits, :preserve_attributes,
        :report_summary, :report_stats,
        :profiling_enabled

      alias_method :profiling_enabled?, :profiling_enabled

      def initialize
        # TODO(v2): Switch to true
        @preserve_traits = false
        @preserve_attributes = false
        @profiling_enabled = ENV["FACTORY_DEFAULT_PROF"] == "1"
        @report_summary = ENV["FACTORY_DEFAULT_SUMMARY"] == "1"
        @report_stats = ENV["FACTORY_DEFAULT_STATS"] == "1"
      end
    end

    class << self
      include Logging

      attr_accessor :current_context
      attr_reader :stats, :profiler

      def init
        TestProf::FactoryBot::Syntax::Methods.include DefaultSyntax
        TestProf::FactoryBot.extend DefaultSyntax
        TestProf::FactoryBot::Strategy::Create.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Build.prepend StrategyExt
        TestProf::FactoryBot::Strategy::Stub.prepend StrategyExt

        @profiler = config.profiling_enabled? ? Profiler.new : NoopProfiler.new
        @enabled = ENV["FACTORY_DEFAULT_DISABLED"] != "1"
        @stats = {}
      end

      def config
        @config ||= Configuration.new
      end

      def configure
        yield config
      end

      # TODO(v2): drop
      def preserve_traits=(val)
        config.preserve_traits = val
      end

      def preserve_attributes=(val)
        config.preserve_attributes = val
      end

      def register(name, obj, **options)
        # Name with traits
        if name.is_a?(Array)
          register_traited_record(*name, obj, **options)
        else
          register_default_record(name, obj, **options)
        end

        obj
      end

      def get(name, traits = nil, overrides = nil)
        return unless enabled?

        record = store[name]
        return unless record

        if traits && (trait_key = record[:traits][traits])
          name = trait_key
          record = store[name]
          traits = nil
        end

        stats[name][:miss] += 1

        if traits && !traits.empty? && record[:preserve_traits]
          return
        end

        object = record[:object]

        if overrides && !overrides.empty? && record[:preserve_attributes]
          overrides.each do |name, value|
            return unless object.respond_to?(name) # rubocop:disable Lint/NonLocalExitFromIterator
            return if object.public_send(name) != value # rubocop:disable Lint/NonLocalExitFromIterator
          end
        end

        stats[name][:miss] -= 1
        stats[name][:hit] += 1

        if record[:context] && (record[:context] != :example)
          object.refind
        else
          object
        end
      end

      def remove(name)
        store.delete(name)
      end

      def reset(context: nil)
        return store.clear unless context

        store.delete_if do |_name, metadata|
          metadata[:context] == context
        end
      end

      def enabled?
        @enabled
      end

      def enable!
        was_enabled = @enabled
        @enabled = true
        return unless block_given?
        yield
      ensure
        @enabled = was_enabled
      end

      def disable!
        was_enabled = @enabled
        @enabled = false
        return unless block_given?
        yield
      ensure
        @enabled = was_enabled
      end

      def print_report
        profiler.print_report
        return unless config.report_stats || config.report_summary

        if stats.empty?
          log :info, "FactoryDefault has not been used"
          return
        end

        msgs = []

        if config.report_stats
          msgs <<
            <<~MSG
              FactoryDefault usage stats:
            MSG

          first_column = stats.keys.map(&:size).max + 2

          msgs << format(
            "%#{first_column}s  %9s  %9s",
            "factory", "hit", "miss"
          )

          msgs << ""
        end

        total_hit = 0
        total_miss = 0

        stats.to_a.sort_by { |(_, v)| -v[:hit] }.each do |(key, record_stats)|
          total_hit += record_stats[:hit]
          total_miss += record_stats[:miss]

          if config.report_stats
            msgs << format(
              "%#{first_column}s  %9d  %9d",
              key, record_stats[:hit], record_stats[:miss]
            )
          end
        end

        msgs << "" if config.report_stats

        msgs <<
          <<~MSG
            FactoryDefault summary: hit=#{total_hit} miss=#{total_miss}
          MSG

        log :info, msgs.join("\n")
      end

      private

      def register_default_record(name, obj, **options)
        store[name] = {object: obj, traits: {}, context: current_context, **options}
        stats[name] ||= {hit: 0, miss: 0}
      end

      def register_traited_record(name, *traits, obj, **options)
        name_with_traits = "#{name}[#{traits.join(",")}]"

        register_default_record(name_with_traits, obj, **options)
        register_default_record(name, obj, **options) unless store[name]

        # Add reference to the traited default to the original default record
        store[name][:traits][traits] = name_with_traits
      end

      def store
        Thread.current[:testprof_factory_default_store] ||= {}
      end
    end
  end
end
