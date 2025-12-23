module ScoutApm
  module BucketNameSplitter
    def bucket_type
      split_metric_name(metric_name).first
    end

    def bucket_name
      split_metric_name(metric_name).last
    end

    def key
      {:bucket => bucket_type, :name => bucket_name}
    end

    private
    def split_metric_name(metric_name)
      metric_name.to_s.split(/\//, 2)
    end

    def scope_hash
      if scope
        scope_bucket, scope_name = split_metric_name(scope)
        {:bucket => scope_bucket, :name => scope_name}
      end
    end
  end
end
