# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module NewRelic
  module Agent
    module Threading
      MAX_THREAD_PROFILE_DEPTH = 500
      UNKNOWN_LINE_NUMBER = -1

      class BacktraceBase
        attr_reader :children

        def initialize
          @children = []
          @depth = 0
        end

        def add_child_unless_present(child)
          child.depth = @depth + 1
          @children << child unless @children.include?(child)
        end

        def add_child(child)
          child.depth = @depth + 1
          @children << child
        end

        def find_child(raw_line)
          @children.find { |child| child.raw_line == raw_line }
        end
      end

      class BacktraceRoot < BacktraceBase
        attr_reader :flattened

        def initialize
          super
          @flattened = []
        end

        def ==(other)
          true # all roots are at the same depth and have no raw_line
        end

        def as_array
          @children.map { |c| c.as_array }.compact
        end

        def aggregate(backtrace)
          current = self

          depth = 0
          backtrace.reverse_each do |frame|
            break if depth >= MAX_THREAD_PROFILE_DEPTH

            existing_node = current.find_child(frame)
            if existing_node
              node = existing_node
            else
              node = Threading::BacktraceNode.new(frame)
              current.add_child(node)
              @flattened << node
            end

            node.runnable_count += 1
            current = node
            depth += 1
          end
        end

        def dump_string
          result = +"#<BacktraceRoot:#{object_id}>"
          child_results = @children.map { |c| c.dump_string(2) }.join("\n")
          result << "\n" unless child_results.empty?
          result << child_results
        end
      end

      class BacktraceNode < BacktraceBase
        attr_reader :file, :method, :line_no, :raw_line, :as_array
        attr_accessor :runnable_count, :depth

        def initialize(line)
          super()
          @raw_line = line
          @children = []
          @runnable_count = 0
        end

        def ==(other)
          (
            @raw_line == other.raw_line &&
            @depth == other.depth &&
            @runnable_count == other.runnable_count
          )
        end

        def mark_for_array_conversion
          @as_array = []
        end

        include NewRelic::Coerce

        def complete_array_conversion
          child_arrays = @children.map { |c| c.as_array }.compact

          file, method, line = parse_backtrace_frame(@raw_line)

          @as_array << [string(file), string(method), line ? int(line) : UNKNOWN_LINE_NUMBER]
          @as_array << int(@runnable_count)
          @as_array << 0
          @as_array << child_arrays
        end

        def dump_string(indent = 0)
          @file, @method, @line_no = parse_backtrace_frame(@raw_line)
          indentation = ' ' * indent
          result = +"#{indentation}#<BacktraceNode:#{object_id} ) + \
                              [#{@runnable_count}] #{@file}:#{@line_no} in #{@method}>"
          child_results = @children.map { |c| c.dump_string(indent + 2) }.join("\n")
          result << "\n" unless child_results.empty?
          result << child_results
        end

        # Returns [filename, method, line number]
        def parse_backtrace_frame(frame)
          frame =~ /([^:]*)(\:(\d+))?\:in `(.*)'/
          [$1, $4, $3] # sic
        end
      end
    end
  end
end
