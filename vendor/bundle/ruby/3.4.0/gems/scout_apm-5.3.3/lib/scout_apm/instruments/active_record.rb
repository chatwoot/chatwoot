require 'scout_apm/utils/sql_sanitizer'

module ScoutApm
  class SqlList
    attr_reader :sqls

    def initialize(sql=nil)
      @sqls = []

      if !sql.nil?
        push(sql)
      end
    end

    def <<(sql)
      push(sql)
    end

    def push(sql)
      if !(Utils::SqlSanitizer === sql)
        sql = Utils::SqlSanitizer.new(sql)
      end
      @sqls << sql
    end

    # All of this one, then all of the other.
    def merge(other)
      @sqls += other.sqls
    end

    def to_s
      @sqls.map{|s| s.to_s }.join(";\n")
    end
  end

  module Instruments
    class ActiveRecord
      attr_reader :context

      def initialize(context)
        @context = context
        @installed = false
      end

      def logger
        context.logger
      end

      def installed?
        @installed
      end

      def install(prepend:)
        if install_via_after_initialize?
          Rails.configuration.after_initialize do
            add_instruments
          end
        else
          add_instruments
        end
      end

      # If we have the right version of rails, we should use the hooks provided
      # to install these instruments
      def install_via_after_initialize?
        defined?(::Rails) &&
          defined?(::Rails::VERSION) &&
          defined?(::Rails::VERSION::MAJOR) &&
          ::Rails::VERSION::MAJOR.to_i == 3 &&
          ::Rails.respond_to?(:configuration)
      end

      def add_instruments
        # Setup Tracer on AR::Base
        if Utils::KlassHelper.defined?("ActiveRecord::Base")
          @installed = true

          ::ActiveRecord::Base.class_eval do
            include ::ScoutApm::Tracer
          end
        end

        # Install #log tracing
        if Utils::KlassHelper.defined?("ActiveRecord::ConnectionAdapters::AbstractAdapter")
          ::ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(ActiveRecordInstruments)
          ::ActiveRecord::ConnectionAdapters::AbstractAdapter.include(Tracer)
        end

        if Utils::KlassHelper.defined?("ActiveRecord::Base")
          ::ActiveRecord::Base.class_eval do
            include ::ScoutApm::Instruments::ActiveRecordUpdateInstruments
          end
        end

        # Disabled until we can determine how to use Module#prepend in the
        # agent. Otherwise, this will cause infinite loops if NewRelic is
        # installed. We can't just use normal Module#include, since the
        # original methods don't call super the way Base#save does
        #
        #if Utils::KlassHelper.defined?("ActiveRecord::Relation")
        #  ::ActiveRecord::Relation.class_eval do
        #    include ::ScoutApm::Instruments::ActiveRecordRelationInstruments
        #  end
        #end

        if Utils::KlassHelper.defined?("ActiveRecord::Querying")
          ::ActiveRecord::Querying.module_eval do
            include ::ScoutApm::Tracer
            include ::ScoutApm::Instruments::ActiveRecordQueryingInstruments
          end
        end

        rails_3_2_or_above = defined?(::ActiveRecord::VERSION::MAJOR) &&
          defined?(::ActiveRecord::VERSION::MINOR) &&
          (::ActiveRecord::VERSION::MAJOR.to_i > 3 ||
           (::ActiveRecord::VERSION::MAJOR.to_i == 3 && ::ActiveRecord::VERSION::MINOR.to_i >= 2))
        if rails_3_2_or_above
          if Utils::KlassHelper.defined?("ActiveRecord::Relation")
            if @context.environment.supports_module_prepend?
              ::ActiveRecord::Relation.module_eval do
                prepend ::ScoutApm::Instruments::ActiveRecordRelationQueryInstruments
              end
            else
              ::ActiveRecord::Relation.module_eval do
                include ::ScoutApm::Instruments::ActiveRecordRelationQueryInstruments
              end
            end
          end
        else
          if Utils::KlassHelper.defined?("ActiveRecord::FinderMethods")
            ::ActiveRecord::FinderMethods.module_eval do
              include ::ScoutApm::Tracer
              include ::ScoutApm::Instruments::ActiveRecordFinderMethodsInstruments
            end
          end
        end

        if Utils::KlassHelper.defined?("ActiveSupport::Notifications")
          ActiveSupport::Notifications.subscribe("instantiation.active_record") do |event_name, start, stop, uuid, payload|
            req = ScoutApm::RequestManager.lookup
            layer = req.current_layer
            if layer && layer.type == "ActiveRecord"
              layer.annotate_layer({
                :class_name => payload[:class_name],
                :record_count => payload[:record_count]
              })
            elsif layer
              logger.debug("Expected layer type: ActiveRecord, got #{layer && layer.type}")
            else
              # noop, no layer at all. We're probably ignoring this req.
            end
          end
        end
      rescue
        logger.warn "ActiveRecord instrumentation exception: #{$!.message}"
      end
    end

    # Contains ActiveRecord instrument, aliasing +ActiveRecord::ConnectionAdapters::AbstractAdapter#log+ calls
    # to trace calls to the database.
    ################################################################################
    # #log instrument.
    #
    # #log is very close to where AR calls out to the database itself.  We have access
    # to the real SQL, and an AR generated "name" for the Query
    #
    ################################################################################
    module ActiveRecordInstruments
      def self.prepended(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting #{instrumented_class.inspect}"
      end

      def log(*args, &block)
        # Extract data from the arguments
        sql, name = args
        metric_name = Utils::ActiveRecordMetricName.new(sql, name)
        desc = SqlList.new(sql)

        # Get current ScoutApm context
        req = ScoutApm::RequestManager.lookup
        current_layer = req.current_layer

        # If we call #log, we have a real query to run, and we've already
        # gotten through the cache gatekeeper. Since we want to only trace real
        # queries, and not repeated identical queries that just hit cache, we
        # mark layer as ignorable initially in #find_by_sql, then only when we
        # know it's a real database call do we mark it back as usable.
        #
        # This flag is later used in SlowRequestConverter to skip adding ignorable layers
        current_layer.annotate_layer(:ignorable => false) if current_layer

        # Either: update the current layer and yield, don't start a new one.
        if current_layer && current_layer.type == "ActiveRecord"
          # TODO: Get rid of call .to_s, need to find this without forcing a previous run of the name logic
          if current_layer.name.to_s == Utils::ActiveRecordMetricName::DEFAULT_METRIC
            current_layer.name = metric_name
          end

          if current_layer.desc.nil?
            current_layer.desc = SqlList.new
          end
          current_layer.desc.merge(desc)

          super(*args, &block)

        # OR: Start a new layer, we didn't pick up instrumentation earlier in the stack.
        else
          layer = ScoutApm::Layer.new("ActiveRecord", metric_name)
          layer.desc = desc
          req.start_layer(layer)
          begin
            super(*args, &block)
          ensure
            req.stop_layer
          end
        end
      end
      ruby2_keywords :log if respond_to?(:ruby2_keywords, true)
    end

    module ActiveRecordInstruments
      def self.prepended(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting #{instrumented_class.inspect}"
      end

      def log(*args, &block)
        # Extract data from the arguments
        sql, name = args
        metric_name = Utils::ActiveRecordMetricName.new(sql, name)
        desc = SqlList.new(sql)

        # Get current ScoutApm context
        req = ScoutApm::RequestManager.lookup
        current_layer = req.current_layer

        # If we call #log, we have a real query to run, and we've already
        # gotten through the cache gatekeeper. Since we want to only trace real
        # queries, and not repeated identical queries that just hit cache, we
        # mark layer as ignorable initially in #find_by_sql, then only when we
        # know it's a real database call do we mark it back as usable.
        #
        # This flag is later used in SlowRequestConverter to skip adding ignorable layers
        current_layer.annotate_layer(:ignorable => false) if current_layer

        # Either: update the current layer and yield, don't start a new one.
        if current_layer && current_layer.type == "ActiveRecord"
          # TODO: Get rid of call .to_s, need to find this without forcing a previous run of the name logic
          if current_layer.name.to_s == Utils::ActiveRecordMetricName::DEFAULT_METRIC
            current_layer.name = metric_name
          end

          if current_layer.desc.nil?
            current_layer.desc = SqlList.new
          end
          current_layer.desc.merge(desc)

          super(*args, &block)

        # OR: Start a new layer, we didn't pick up instrumentation earlier in the stack.
        else
          layer = ScoutApm::Layer.new("ActiveRecord", metric_name)
          layer.desc = desc
          req.start_layer(layer)
          begin
            super(*args, &block)
          ensure
            req.stop_layer
          end
        end
      end
      ruby2_keywords :log if respond_to?(:ruby2_keywords, true)
    end

    ################################################################################
    # Entry-point of instruments.
    #
    # Instrumentation starts in ActiveRecord::Relation#exec_queries (Rails >=
    # 3.2.0) or ActiveRecord::FinderMethods#find_with_assocations (previous
    # Rails versions).
    #
    # ActiveRecord::Querying#find_by_sql is instrumented in all Rails versions
    # even though it is also invoked by #exec_queries/#find_by_associations
    # because it can be invoked directly from user code (e.g.,
    # Post.find_by_sql("SELECT * FROM posts")). The layer started by
    # #exec_queries/#find_by_assocations is marked to ignore children, so it
    # will not cause duplicate layers in the former case.
    #
    # These methods are early in the chain of calls invoked when executing an
    # ActiveRecord query, before the cache is consulted. If the query is later
    # determined to be a cache miss, `#log` will be invoked, which we also
    # instrument, and more details will be filled in (name, sql).
    #
    # Caveats:
    #   * We don't have a name for the query yet.
    #   * The query hasn't hit the cache yet. In the case of a cache hit, we
    #     won't hit #log, so won't get a name, leaving the misleading default.
    #   * One call here can result in several calls to #log, especially in the
    #     case where Rails needs to load the schema details for the table being
    #     queried.
    ################################################################################

    module ActiveRecordQueryingInstruments
      def self.included(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting ActiveRecord::Querying - #{instrumented_class.inspect}"
        instrumented_class.class_eval do
          unless instrumented_class.method_defined?(:find_by_sql_without_scout_instruments)
            alias_method :find_by_sql_without_scout_instruments, :find_by_sql
            alias_method :find_by_sql, :find_by_sql_with_scout_instruments
          end
        end
      end

      def find_by_sql_with_scout_instruments(*args, **kwargs, &block)
        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName::DEFAULT_METRIC)
        layer.annotate_layer(:ignorable => true)
        req.start_layer(layer)
        req.ignore_children!
        begin
          if ScoutApm::Agent.instance.context.environment.supports_kwarg_delegation?
            find_by_sql_without_scout_instruments(*args, **kwargs, &block)
          else
            find_by_sql_without_scout_instruments(*args, &block)
          end
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end
    end

    module ActiveRecordFinderMethodsInstruments
      def self.included(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting ActiveRecord::FinderMethods - #{instrumented_class.inspect}"
        instrumented_class.class_eval do
          unless instrumented_class.method_defined?(:find_with_associations_without_scout_instruments)
            alias_method :find_with_associations_without_scout_instruments, :find_with_associations
            alias_method :find_with_associations, :find_with_associations_with_scout_instruments
          end
        end
      end

      def find_with_associations_with_scout_instruments(*args, &block)
        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName::DEFAULT_METRIC)
        layer.annotate_layer(:ignorable => true)
        layer.desc = SqlList.new
        req.start_layer(layer)
        req.ignore_children!
        begin
          find_with_associations_without_scout_instruments(*args, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end
    end

    module ActiveRecordRelationQueryInstruments
      def self.prepended(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting ActiveRecord::Relation#exec_queries - #{instrumented_class.inspect} (prepending)"
      end

      def self.included(instrumented_class)
        ScoutApm::Agent.instance.context.logger.info "Instrumenting ActiveRecord::Relation#exec_queries - #{instrumented_class.inspect}"
        instrumented_class.class_eval do
          unless instrumented_class.method_defined?(:exec_queries_without_scout_instruments)
            alias_method :exec_queries_without_scout_instruments, :exec_queries
            alias_method :exec_queries, :exec_queries_with_scout_instruments
          end
        end
      end

      def exec_queries(*args, &block)
        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName::DEFAULT_METRIC)
        layer.annotate_layer(:ignorable => true)
        layer.desc = SqlList.new
        req.start_layer(layer)
        req.ignore_children!
        begin
          if ScoutApm::Environment.instance.supports_module_prepend?
            super(*args, &block)
          else
            exec_queries_without_scout_instruments(*args, &block)
          end
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end

      # If prepend is not supported, rename the method and use
      # alias_method_style chaining instead
      if !ScoutApm::Environment.instance.supports_module_prepend?
        alias_method :exec_queries_with_scout_instruments, :exec_queries
        remove_method :exec_queries
      end
    end

    module ActiveRecordUpdateInstruments
      def save(*args, **options, &block)
        model = self.class.name
        operation = self.persisted? ? "Update" : "Create"

        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName.new("", "#{model} #{operation}"))
        layer.desc = SqlList.new
        req.start_layer(layer)
        req.ignore_children!
        begin
          super(*args, **options, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end

      def save!(*args, **options, &block)
        model = self.class.name
        operation = self.persisted? ? "Update" : "Create"

        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName.new("", "#{model} #{operation}"))
        req.start_layer(layer)
        req.ignore_children!
        begin
          super(*args, **options, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end
    end

    module ActiveRecordRelationInstruments
      def self.included(instrumented_class)
        ::ActiveRecord::Relation.class_eval do
          alias_method :update_all_without_scout_instruments, :update_all
          alias_method :update_all, :update_all_with_scout_instruments

          alias_method :delete_all_without_scout_instruments, :delete_all
          alias_method :delete_all, :delete_all_with_scout_instruments

          alias_method :destroy_all_without_scout_instruments, :destroy_all
          alias_method :destroy_all, :destroy_all_with_scout_instruments
        end
      end

      def update_all_with_scout_instruments(*args, &block)
        model = self.name

        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName.new("", "#{model} Update"))
        req.start_layer(layer)
        req.ignore_children!
        begin
          update_all_without_scout_instruments(*args, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end

      def delete_all_with_scout_instruments(*args, &block)
        model = self.name

        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName.new("", "#{model} Delete"))
        req.start_layer(layer)
        req.ignore_children!
        begin
          delete_all_without_scout_instruments(*args, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end

      def destroy_all_with_scout_instruments(*args, &block)
        model = self.name

        req = ScoutApm::RequestManager.lookup
        layer = ScoutApm::Layer.new("ActiveRecord", Utils::ActiveRecordMetricName.new("", "#{model} Delete"))
        req.start_layer(layer)
        req.ignore_children!
        begin
          destroy_all_without_scout_instruments(*args, &block)
        ensure
          req.acknowledge_children!
          req.stop_layer
        end
      end
    end
  end
end
