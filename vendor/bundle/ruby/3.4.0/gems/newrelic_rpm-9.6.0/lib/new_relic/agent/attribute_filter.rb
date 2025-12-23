# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# This class applies filtering rules as specified in the Agent Attributes
# cross-agent spec.
#
# Instances of it are constructed by deriving a set of rules from the agent
# configuration. Instances are immutable once they are constructed - if the
# config changes, a new instance should be constructed and swapped in to
# replace the existing one.
#
# The #apply method is the main external interface of this class. It takes an
# attribute name and a set of default destinations (represented as a bitfield)
# and returns a set of actual destinations after applying the filtering rules
# specified in the config.
#
# Each set of destinations is represented as a bitfield, where the bit positions
# specified in the DST_* constants are used to indicate whether an attribute
# should be sent to the corresponding destination.
#
# The choice of a bitfield here rather than an Array was made to avoid the need
# for any transient object allocations during the application of rules. Since
# rule application will happen once per attribute per transaction, this is a hot
# code path.
#
# The algorithm for applying filtering rules is as follows:
#
# 1. Start with a bitfield representing the set of default destinations passed
#    in to #apply.
# 2. Mask this bitfield against the set of destinations that have attribute
#    enabled at all.
# 3. Traverse the list of rules in order (more on the ordering later), applying
#    each matching rule, but taking care to not let rules override the enabled
#    status of each destination. Each matching rule may mutate the bitfield.
# 4. Return the resulting bitfield after all rules have been applied.
#
# Each rule consists of a name, a flag indicating whether it ends with a
# wildcard, a bitfield representing the set of destinations that it applies to,
# and a flag specifying whether it is an include or exclude rule.
#
# During construction, rules are sorted according to the following criteria:
#
# 1. First, the names are compared lexicographically. This has the impact of
#    forcing shorter (more general) rules towards the top of the list and longer
#    (more specific) rules towards the bottom. This is important, because the
#    Agent Attributes spec stipulates that the most specific rule for a given
#    destination should take precedence. Since rules are applied top-to-bottom,
#    this sorting guarantees that the most specific rule will be applied last.
# 2. If the names are identical, we next examine the wildcard flag. Rules ending
#    with a wildcard are considered more general (and thus 'less than') rules
#    not ending with a wildcard.
# 3. If the names and wildcard flags are identical, we next examine whether the
#    rules being compared are include or exclude rules. Exclude rules have
#    precedence by the spec, so they are considered 'greater than' include
#    rules.
#
# This approach to rule evaluation was taken from the PHP agent's
# implementation.
#

module NewRelic
  module Agent
    class AttributeFilter
      DST_NONE = 0x0

      DST_TRANSACTION_EVENTS = 1 << 0
      DST_TRANSACTION_TRACER = 1 << 1
      DST_ERROR_COLLECTOR = 1 << 2
      DST_BROWSER_MONITORING = 1 << 3
      DST_SPAN_EVENTS = 1 << 4
      DST_TRANSACTION_SEGMENTS = 1 << 5

      DST_ALL = 0x3f

      attr_reader :rules

      def initialize(config)
        prep_enabled_destinations(config)
        prep_rules(config)

        # We're ok to cache high security for fast lookup because the attribute
        # filter is re-generated on any significant config change.
        @high_security = config[:high_security]

        setup_key_cache
        cache_prefix_denylist
      end

      def prep_enabled_destinations(config)
        @enabled_destinations = config[:'attributes.enabled'] ? enabled_destinations_for_attributes(config) : DST_NONE
      end

      def enabled_destinations_for_attributes(config)
        destinations = DST_NONE
        destinations |= DST_TRANSACTION_TRACER if config[:'transaction_tracer.attributes.enabled']
        destinations |= DST_TRANSACTION_EVENTS if config[:'transaction_events.attributes.enabled']
        destinations |= DST_ERROR_COLLECTOR if config[:'error_collector.attributes.enabled']
        destinations |= DST_BROWSER_MONITORING if config[:'browser_monitoring.attributes.enabled']
        destinations |= DST_SPAN_EVENTS if config[:'span_events.attributes.enabled']
        destinations |= DST_TRANSACTION_SEGMENTS if config[:'transaction_segments.attributes.enabled']
        destinations
      end

      def prep_rules(config)
        @rules = []
        prep_attributes_exclude_rules(config)
        prep_capture_params_rules(config)
        prep_datastore_rules(config)
        prep_attributes_include_rules(config)
        build_uri_rule(config[:'attributes.exclude'])
        @rules.sort!
      end

      def prep_attributes_exclude_rules(config)
        build_rule(config[:'attributes.exclude'], DST_ALL, false)
        build_rule(config[:'transaction_tracer.attributes.exclude'], DST_TRANSACTION_TRACER, false)
        build_rule(config[:'transaction_events.attributes.exclude'], DST_TRANSACTION_EVENTS, false)
        build_rule(config[:'error_collector.attributes.exclude'], DST_ERROR_COLLECTOR, false)
        build_rule(config[:'browser_monitoring.attributes.exclude'], DST_BROWSER_MONITORING, false)
        build_rule(config[:'span_events.attributes.exclude'], DST_SPAN_EVENTS, false)
        build_rule(config[:'transaction_segments.attributes.exclude'], DST_TRANSACTION_SEGMENTS, false)
      end

      def prep_capture_params_rules(config)
        build_rule(['request.parameters.*'], include_destinations_for_capture_params(config[:capture_params]), true)
      end

      def prep_datastore_rules(config)
        build_rule(%w[host port_path_or_id], DST_TRANSACTION_SEGMENTS, config[:'datastore_tracer.instance_reporting.enabled'])
        build_rule(['database_name'], DST_TRANSACTION_SEGMENTS, config[:'datastore_tracer.database_name_reporting.enabled'])
      end

      def prep_attributes_include_rules(config)
        build_rule(config[:'attributes.include'], DST_ALL, true)
        build_rule(config[:'transaction_tracer.attributes.include'], DST_TRANSACTION_TRACER, true)
        build_rule(config[:'transaction_events.attributes.include'], DST_TRANSACTION_EVENTS, true)
        build_rule(config[:'error_collector.attributes.include'], DST_ERROR_COLLECTOR, true)
        build_rule(config[:'browser_monitoring.attributes.include'], DST_BROWSER_MONITORING, true)
        build_rule(config[:'span_events.attributes.include'], DST_SPAN_EVENTS, true)
        build_rule(config[:'transaction_segments.attributes.include'], DST_TRANSACTION_SEGMENTS, true)
      end

      # Note the key_cache is a global cache, accessible by multiple threads,
      # but is intentionally left unsynchronized for liveness. Writes will always
      # involve writing the same boolean value for each key, so there is no
      # worry of one value clobbering another. For reads, if a value hasn't been
      # written to the cache yet, the worst that will happen is that it will run
      # through the filter rules again. Both reads and writes will become
      # eventually consistent.

      def setup_key_cache
        destinations = [
          DST_TRANSACTION_EVENTS,
          DST_TRANSACTION_TRACER,
          DST_ERROR_COLLECTOR,
          DST_BROWSER_MONITORING,
          DST_SPAN_EVENTS,
          DST_TRANSACTION_SEGMENTS,
          DST_ALL
        ]

        @key_cache = destinations.inject({}) do |memo, destination|
          memo[destination] = {}
          memo
        end
      end

      def include_destinations_for_capture_params(capturing)
        if capturing
          DST_TRANSACTION_TRACER | DST_ERROR_COLLECTOR
        else
          DST_NONE
        end
      end

      def build_rule(attribute_names, destinations, is_include)
        attribute_names.each do |attribute_name|
          rule = AttributeFilterRule.new(attribute_name, destinations, is_include)
          @rules << rule unless rule.empty?
        end
      end

      def build_uri_rule(excluded_attributes)
        uri_aliases = %w[uri url request_uri request.uri http.url]

        if (excluded_attributes & uri_aliases).size > 0
          build_rule(uri_aliases - excluded_attributes, DST_ALL, false)
        end
      end

      def apply(attribute_name, default_destinations)
        return DST_NONE if @enabled_destinations == DST_NONE

        destinations = default_destinations
        attribute_name = attribute_name.to_s

        @rules.each do |rule|
          if rule.match?(attribute_name)
            if rule.is_include
              destinations |= rule.destinations
            else
              destinations &= rule.destinations
            end
          end
        end

        destinations & @enabled_destinations
      end

      def allows?(allowed_destinations, requested_destination)
        allowed_destinations & requested_destination == requested_destination
      end

      def allows_key?(key, destination)
        return false unless destination & @enabled_destinations == destination

        value = @key_cache[destination][key]

        if value.nil?
          allowed_destinations = apply(key, destination)
          @key_cache[destination][key] = allows?(allowed_destinations, destination)
        else
          value
        end
      end

      def high_security?
        @high_security
      end

      # For attribute prefixes where we know the default destinations will
      # always be DST_NONE, we can statically determine that any attribute
      # starting with the prefix will not be allowed unless there's an include
      # rule that might match attributes starting with it.
      #
      # This allows us to skip significant preprocessing work (hash/array
      # flattening and type coercion) for HTTP request parameters and job
      # arguments for Sidekiq and Resque in the common case, since none of
      # these attributes are captured by default.
      #
      def cache_prefix_denylist
        @prefix_denylist = {}
        @prefix_denylist[:'request.parameters'] = true unless might_allow_prefix_uncached?(:'request.parameters')
        @prefix_denylist[:'job.sidekiq.args'] = true unless might_allow_prefix_uncached?(:'job.sidekiq.args')
        @prefix_denylist[:'job.resque.args'] = true unless might_allow_prefix_uncached?(:'job.resque.args')
      end

      # Note that the given prefix *must* be a Symbol
      def might_allow_prefix?(prefix)
        !@prefix_denylist.include?(prefix)
      end

      def might_allow_prefix_uncached?(prefix)
        prefix = prefix.to_s
        @rules.any? do |rule|
          if rule.is_include
            if rule.wildcard
              if rule.attribute_name.size > prefix.size
                rule.attribute_name.start_with?(prefix)
              else
                prefix.start_with?(rule.attribute_name)
              end
            else
              rule.attribute_name.start_with?(prefix)
            end
          end
        end
      end
    end

    class AttributeFilterRule
      attr_reader :attribute_name, :destinations, :is_include, :wildcard

      def initialize(attribute_name, destinations, is_include)
        @attribute_name = attribute_name.sub(/\*$/, '')
        @wildcard = attribute_name.end_with?('*')
        @is_include = is_include
        @destinations = is_include ? destinations : ~destinations
      end

      # Rules are sorted from least specific to most specific
      #
      # All else being the same, wildcards are considered less specific
      # All else being the same, include rules are less specific than excludes
      def <=>(other)
        name_cmp = @attribute_name <=> other.attribute_name
        return name_cmp unless name_cmp == 0

        if wildcard != other.wildcard
          return wildcard ? -1 : 1
        end

        if is_include != other.is_include
          return is_include ? -1 : 1
        end

        return 0
      end

      def match?(name)
        if wildcard
          name.start_with?(@attribute_name)
        else
          @attribute_name == name
        end
      end

      def empty?
        if is_include
          @destinations == AttributeFilter::DST_NONE
        else
          @destinations == AttributeFilter::DST_ALL
        end
      end
    end
  end
end
