# frozen_string_literal: true

module Rack
  class MiniProfiler
    module TimerStruct

      # TimerStruct::Page
      #   Root: TimerStruct::Request
      #     :has_many TimerStruct::Request children
      #     :has_many TimerStruct::Sql children
      #     :has_many TimerStruct::Custom children
      class Page < TimerStruct::Base
        class << self
          def from_hash(hash)
            hash = symbolize_hash(hash)
            if hash.key?(:custom_timing_names)
              hash[:custom_timing_names] = []
            end
            hash.delete(:started_formatted)
            if hash.key?(:duration_milliseconds)
              hash[:duration_milliseconds] = 0
            end
            page = self.allocate
            page.instance_variable_set(:@attributes, hash)
            page
          end

          private

          def symbolize_hash(hash)
            new_hash = {}
            hash.each do |k, v|
              sym_k = String === k ? k.to_sym : k
              if Hash === v
                new_hash[sym_k] = symbolize_hash(v)
              elsif Array === v
                new_hash[sym_k] = symbolize_array(v)
              else
                new_hash[sym_k] = v
              end
            end
            new_hash
          end

          def symbolize_array(array)
            array.map do |item|
              if Array === item
                symbolize_array(item)
              elsif Hash === item
                symbolize_hash(item)
              else
                item
              end
            end
          end
        end

        attr_reader :attributes

        def initialize(env)
          timer_id     = MiniProfiler.generate_id
          page_name    = env['PATH_INFO']
          started_at   = (Time.now.to_f * 1000).to_i
          started      = (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i
          machine_name = env['SERVER_NAME']
          super(
            id: timer_id,
            name: page_name,
            started: started,
            started_at: started_at,
            machine_name: machine_name,
            level: 0,
            user: "unknown user",
            has_user_viewed: false,
            client_timings: nil,
            duration_milliseconds: 0,
            has_trivial_timings: true,
            has_all_trivial_timings: false,
            trivial_duration_threshold_milliseconds: 2,
            head: nil,
            sql_count: 0,
            duration_milliseconds_in_sql: 0,
            has_sql_timings: true,
            has_duplicate_sql_timings: false,
            executed_readers: 0,
            executed_scalars: 0,
            executed_non_queries: 0,
            custom_timing_names: [],
            custom_timing_stats: {},
            custom_fields: {},
            has_flamegraph: false,
            flamegraph: nil
          )
          self[:request_method] = env['REQUEST_METHOD']
          self[:request_path] = env['PATH_INFO']
          name = "#{env['REQUEST_METHOD']} http://#{env['SERVER_NAME']}:#{env['SERVER_PORT']}#{env['SCRIPT_NAME']}#{env['PATH_INFO']}"
          self[:root] = TimerStruct::Request.createRoot(name, self)
        end

        def name
          @attributes[:name]
        end

        def duration_ms
          @attributes[:root][:duration_milliseconds]
        end

        def duration_ms_in_sql
          @attributes[:duration_milliseconds_in_sql]
        end

        def root
          @attributes[:root]
        end

        def attributes_to_serialize
          @attributes.keys - [:flamegraph]
        end

        def to_json(*a)
          ::JSON.generate(@attributes.slice(*attributes_to_serialize).merge(extra_json))
        end

        def as_json(options = nil)
          super(options).slice(*attributes_to_serialize.map(&:to_s)).merge!(extra_json)
        end

        def extra_json
          {
            started_formatted: '/Date(%d)/' % @attributes[:started_at],
            duration_milliseconds: @attributes[:root][:duration_milliseconds],
            custom_timing_names: @attributes[:custom_timing_stats].keys.sort
          }
        end
      end
    end
  end
end
