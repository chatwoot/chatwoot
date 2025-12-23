module Barnes
  module Instruments
    class PumaInstrument
      # This class is responsible for consuming a puma
      # generated stats hash that can come in two "flavors"
      # one is a "single process" server which will look like this:
      #
      #    { "backlog": 0, "running": 0, "pool_capacity": 16 }
      #
      # The other is a multiple cluster server that will look like this:
      #
      #    {"workers"=>2, "phase"=>0, "booted_workers"=>2, "old_workers"=>0, "worker_status"=>[{"pid"=>35020, "index"=>0, "phase"=>0, "booted"=>true, "last_checkin"=>"2018-05-21T19:53:18Z", "last_status"=>{"backlog"=>0, "running"=>5, "pool_capacity"=>5}}, {"pid"=>35021, "index"=>1, "phase"=>0, "booted"=>true, "last_checkin"=>"2018-05-21T19:53:18Z", "last_status"=>{"backlog"=>0, "running"=>5, "pool_capacity"=>5}}]}
      #
      class StatValue
        attr_reader :stats, :key

        def initialize(stats, key)
          @stats   = stats
          @key     = key
          @cluster = stats.key?("worker_status")
        end

        def single?
          !cluster?
        end

        def cluster?
          @cluster
        end

        # For single worker process use value directly
        # for multiple workers use the sum.
        #
        # https://github.com/puma/puma/pull/1532
        def value
          return stats[key] if single?
          first_worker = stats["worker_status"].first
          return nil unless first_worker && first_worker["last_status"].key?(key)

          value = 0
          stats["worker_status"].each do |worker_status|
            value += worker_status["last_status"][key] || 0
          end
          return value
        end
      end
    end
  end
end