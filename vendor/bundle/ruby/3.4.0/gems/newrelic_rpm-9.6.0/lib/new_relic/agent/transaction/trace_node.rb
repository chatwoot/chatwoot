# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    class Transaction
      class TraceNode
        attr_reader :entry_timestamp
        # The exit timestamp will be relative except for the outermost sample which will
        # have a timestamp.
        attr_accessor :exit_timestamp

        attr_reader :parent_node

        attr_accessor :metric_name

        UNKNOWN_NODE_NAME = '<unknown>'.freeze

        def initialize(metric_name, relative_start, relative_end = nil, params = nil, parent = nil)
          @entry_timestamp = relative_start
          @metric_name = metric_name || UNKNOWN_NODE_NAME
          @exit_timestamp = relative_end
          @children = nil
          @params = select_allowed_params(params)
          @parent_node = parent
        end

        def select_allowed_params(params)
          return unless params

          params.select do |p|
            NewRelic::Agent.instance.attribute_filter.allows_key?(p, AttributeFilter::DST_TRANSACTION_SEGMENTS)
          end
        end

        # sets the final timestamp on a node to indicate the exit
        # point of the node
        def end_trace(timestamp)
          @exit_timestamp = timestamp
        end

        def to_s
          to_debug_str(0)
        end

        def to_array
          params = @params || NewRelic::EMPTY_HASH
          [NewRelic::Helper.time_to_millis(@entry_timestamp),
            NewRelic::Helper.time_to_millis(@exit_timestamp),
            NewRelic::Coerce.string(@metric_name),
            params] +
            [(@children ? @children.map { |s| s.to_array } : NewRelic::EMPTY_ARRAY)]
        end

        def path_string
          "#{metric_name}[#{children.collect { |node| node.path_string }.join('')}]"
        end

        def to_s_compact
          str = +''
          str << metric_name
          if children.any?
            str << "{#{children.map { |cs| cs.to_s_compact }.join(',')}}"
          end
          str
        end

        def to_debug_str(depth)
          tab = (+'  ') * depth
          s = tab.clone
          s << ">> #{'%3i ms' % (@entry_timestamp * 1000)} [#{self.class.name.split('::').last}] #{metric_name} \n"
          unless params.empty?
            params.each do |k, v|
              s << "#{tab}    -#{'%-16s' % k}: #{v.to_s[0..80]}\n"
            end
          end
          children.each do |cs|
            s << cs.to_debug_str(depth + 1)
          end
          s << tab + '<< '
          s << case @exit_timestamp
          when nil then ' n/a'
          when Numeric then '%3i ms' % (@exit_timestamp * 1000)
          else @exit_timestamp.to_s
          end
          s << " #{metric_name}\n"
        end

        def children
          @children ||= []
        end

        attr_writer :children

        # return the total duration of this node
        def duration
          (@exit_timestamp - @entry_timestamp).to_f
        end

        # return the duration of this node without
        # including the time in the called nodes
        def exclusive_duration
          d = duration

          children.each do |node|
            d -= node.duration
          end
          d
        end

        def count_nodes
          count = 1
          children.each { |node| count += node.count_nodes }
          count
        end

        def params
          @params ||= {}
        end

        attr_writer :params

        def []=(key, value)
          # only create a parameters field if a parameter is set; this will save
          # bandwidth etc as most nodes have no parameters
          params[key] = value
        end

        def [](key)
          params[key]
        end

        # call the provided block for this node and each
        # of the called nodes
        def each_node(&block)
          yield(self)

          @children&.each do |node|
            node.each_node(&block)
          end
        end

        # call the provided block for this node and each
        # of the called nodes while keeping track of nested nodes
        def each_node_with_nest_tracking(&block)
          summary = yield(self)
          summary.current_nest_count += 1 if summary

          # no then branch coverage
          # rubocop:disable Style/SafeNavigation
          if @children
            @children.each do |node|
              node.each_node_with_nest_tracking(&block)
            end
          end
          # rubocop:enable Style/SafeNavigation

          summary.current_nest_count -= 1 if summary
        end

        def explain_sql
          return params[:explain_plan] if params.key?(:explain_plan)

          statement = params[:sql]
          return nil unless statement.is_a?(Database::Statement)

          NewRelic::Agent::Database.explain_sql(statement)
        end

        def obfuscated_sql
          NewRelic::Agent::Database.obfuscate_sql(params[:sql].sql)
        end

        def parent_node=(s)
          @parent_node = s
        end
      end
    end
  end
end
