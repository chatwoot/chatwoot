# frozen_string_literal: true

module Rack
  class MiniProfiler
    class AbstractStore

      # maximum age of allowed tokens before cycling in seconds
      MAX_TOKEN_AGE = 1800

      def save(page_struct)
        raise NotImplementedError.new("save is not implemented")
      end

      def load(id)
        raise NotImplementedError.new("load is not implemented")
      end

      def set_unviewed(user, id)
        raise NotImplementedError.new("set_unviewed is not implemented")
      end

      def set_viewed(user, id)
        raise NotImplementedError.new("set_viewed is not implemented")
      end

      def set_all_unviewed(user, ids)
        raise NotImplementedError.new("set_all_unviewed is not implemented")
      end

      def get_unviewed_ids(user)
        raise NotImplementedError.new("get_unviewed_ids is not implemented")
      end

      def diagnostics(user)
        # this is opt in, no need to explode if not implemented
        ""
      end

      # a list of tokens that are permitted to access profiler in explicit mode
      def allowed_tokens
        raise NotImplementedError.new("allowed_tokens is not implemented")
      end

      def should_take_snapshot?(period)
        raise NotImplementedError.new("should_take_snapshot? is not implemented")
      end

      def push_snapshot(page_struct, group_name, config)
        raise NotImplementedError.new("push_snapshot is not implemented")
      end

      # returns a hash where the keys are group names and the values
      # are hashes that contain 3 keys:
      #   1. `:worst_score` => the duration of the worst/slowest snapshot in the group (float)
      #   2. `:best_score` => the duration of the best/fastest snapshot in the group (float)
      #   3. `:snapshots_count` => the number of snapshots in the group (integer)
      def fetch_snapshots_overview
        raise NotImplementedError.new("fetch_snapshots_overview is not implemented")
      end

      # @param group_name [String]
      # @return [Array<Rack::MiniProfiler::TimerStruct::Page>] list of snapshots of the group. Blank array if the group doesn't exist.
      def fetch_snapshots_group(group_name)
        raise NotImplementedError.new("fetch_snapshots_group is not implemented")
      end

      def load_snapshot(id, group_name)
        raise NotImplementedError.new("load_snapshot is not implemented")
      end

      def snapshots_overview
        groups = fetch_snapshots_overview.to_a
        groups.sort_by! { |name, hash| hash[:worst_score] }
        groups.reverse!
        groups.map! { |name, hash| hash.merge(name: name) }
        groups
      end

      def snapshots_group(group_name)
        snapshots = fetch_snapshots_group(group_name)
        data = []
        snapshots.each do |snapshot|
          data << {
            id: snapshot[:id],
            duration: snapshot.duration_ms,
            sql_count: snapshot[:sql_count],
            timestamp: snapshot[:started_at],
            custom_fields: snapshot[:custom_fields]
          }
        end
        data.sort_by! { |s| s[:duration] }
        data.reverse!
        data
      end
    end
  end
end
