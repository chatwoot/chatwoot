module Sentry
  module Sidekiq
    class ContextFilter
      ACTIVEJOB_RESERVED_PREFIX_REGEX = /^_aj_/.freeze
      SIDEKIQ_NAME = "Sidekiq".freeze

      attr_reader :context

      def initialize(context)
        @context = context
        @has_global_id = defined?(GlobalID)
      end

      # Once an ActiveJob is queued, ActiveRecord references get serialized into
      # some internal reserved keys, such as _aj_globalid.
      #
      # The problem is, if this job in turn gets queued back into ActiveJob with
      # these magic reserved keys, ActiveJob will throw up and error. We want to
      # capture these and mutate the keys so we can sanely report it.
      def filtered
        filtered_context = filter_context(context)

        if job_entry = filtered_context.delete(:job)
          job_entry.each do |k, v|
            filtered_context[k] = v
          end
        end

        # Sidekiq 7.0 started adding `_config` to the context, which is not easily serialisable
        # And it's presence could be confusing so it's better to remove it until we decided to add it for a reason
        filtered_context.delete(:_config)
        filtered_context
      end

      def transaction_name
        class_name = (context["wrapped"] || context["class"] ||
                      (context[:job] && (context[:job]["wrapped"] || context[:job]["class"]))
                    )

        if class_name
          "#{SIDEKIQ_NAME}/#{class_name}"
        elsif context[:event]
          "#{SIDEKIQ_NAME}/#{context[:event]}"
        else
          SIDEKIQ_NAME
        end
      end

      private

      def filter_context(hash)
        case hash
        when Array
          hash.map { |arg| filter_context(arg) }
        when Hash
          Hash[hash.map { |key, value| filter_context_hash(key, value) }]
        else
          if has_global_id? && hash.is_a?(GlobalID)
            hash.to_s
          else
            hash
          end
        end
      end

      def filter_context_hash(key, value)
        key = key.to_s.sub(ACTIVEJOB_RESERVED_PREFIX_REGEX, "") if key.match(ACTIVEJOB_RESERVED_PREFIX_REGEX)
        [key, filter_context(value)]
      end

      def has_global_id?
        @has_global_id
      end
    end
  end
end
