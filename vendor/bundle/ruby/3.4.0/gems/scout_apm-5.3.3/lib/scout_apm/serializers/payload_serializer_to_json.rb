module ScoutApm
  module Serializers
    module PayloadSerializerToJson
      class << self
        def serialize(metadata, metrics, slow_transactions, jobs, slow_jobs, histograms, db_query_metrics, external_service_metrics, traces)
          metadata.merge!({:payload_version => 2})

          jsonify_hash({:metadata => metadata,
                        :metrics => rearrange_the_metrics(metrics),
                        :slow_transactions => rearrange_the_slow_transactions(slow_transactions),
                        :jobs => JobsSerializerToJson.new(jobs).as_json,
                        :slow_jobs => SlowJobsSerializerToJson.new(slow_jobs).as_json,
                        :histograms => HistogramsSerializerToJson.new(histograms).as_json,
                        :db_metrics => {
                          :query => DbQuerySerializerToJson.new(db_query_metrics).as_json,
                        },
                        :es_metrics => {
                          :http => ExternalServiceSerializerToJson.new(external_service_metrics).as_json,
                        },
                        :span_traces => traces.map{ |t| t.as_json },
          })
        end

        # For the old style of metric serializing.
        def rearrange_the_metrics(metrics)
          metrics.to_a.map do |meta, stats|
            stats.as_json.merge(:key => meta.as_json)
          end
        end

        # takes an array of slow transactions
        def rearrange_the_slow_transactions(slow_transactions)
          slow_transactions.to_a.map { |t| rearrange_slow_transaction(t) }
        end

        # takes just one slow transaction
        def rearrange_slow_transaction(slow_t)
          slow_t.as_json.merge(:metrics => rearrange_the_metrics(slow_t.metrics), :allocation_metrics => rearrange_the_metrics(slow_t.allocation_metrics))
        end

        def jsonify_hash(hash)
          str_parts = []
          hash.each do |key, value|
            formatted_key = format_by_type(key)
            formatted_value = format_by_type(value)
            str_parts << "#{formatted_key}:#{formatted_value}"
          end
          "{#{str_parts.join(",")}}"
        end

        ESCAPE_MAPPINGS = {
          # Stackoverflow answer on gsub matches and backslashes
          # https://stackoverflow.com/a/4149087/2705125
          '\\' => '\\\\\\\\',
          "\b" => '\\b',
          "\t" => '\\t',
          "\n" => '\\n',
          "\f" => '\\f',
          "\r" => '\\r',
          '"'  => '\\"',
        }

        def escape(string)
          ESCAPE_MAPPINGS.inject(string.to_s) {|s, (bad, good)| 
            s.gsub(bad, good)
          }
        end

        def format_by_type(formatee)
          case formatee
          when Hash
            jsonify_hash(formatee)
          when Array
            all_the_elements = formatee.map {|value_guy| format_by_type(value_guy)}
            "[#{all_the_elements.join(",")}]"
          when Numeric
            formatee
          when Time
            %Q["#{formatee.iso8601}"]
          when nil
            "null"
          else # strings and everything
            %Q["#{escape(formatee)}"]
          end
        end
      end
    end
  end
end
