# frozen_string_literal: true

require_relative '../../core/environment/ext'

require_relative 'ext'

module Datadog
  module Tracing
    module Metadata
      # Adds metadata & metric tag behavior
      # @public_api
      module Tagging
        # This limit is for numeric tags because uint64 could end up rounded.
        NUMERIC_TAG_SIZE_RANGE = (-1 << 53..1 << 53).freeze

        # Some associated values should always be sent as Tags, never as Metrics, regardless
        # if their value is numeric or not.
        # The Datadog agent will look for these values only as Tags, not Metrics.
        # @see https://github.com/DataDog/datadog-agent/blob/2ae2cdd315bcda53166dd8fa0dedcfc448087b9d/pkg/trace/stats/aggregation.go#L13-L17
        ENSURE_AGENT_TAGS = {
          Ext::Distributed::TAG_ORIGIN => true,
          Core::Environment::Ext::TAG_VERSION => true,
          Ext::HTTP::TAG_STATUS_CODE => true,
          Ext::NET::TAG_HOSTNAME => true
        }.freeze

        # Return the tag with the given key, nil if it doesn't exist.
        def get_tag(key)
          meta[key] || metrics[key]
        end

        # Set the given key / value tag pair on the span. Keys and values
        # must be strings. A valid example is:
        #
        #   span.set_tag('http.method', request.method)
        def set_tag(key, value = nil)
          # Keys must be unique between tags and metrics
          metrics.delete(key)

          # DEV: This is necessary because the agent looks at `meta[key]`, not `metrics[key]`.
          value = value.to_s if ENSURE_AGENT_TAGS[key]

          # NOTE: Adding numeric tags as metrics is stop-gap support
          #       for numeric typed tags. Eventually they will become
          #       tags again.
          # Any numeric that is not an integer greater than max size is logged as a metric.
          # Everything else gets logged as a tag.
          if value.is_a?(Numeric) && !(value.is_a?(Integer) && !NUMERIC_TAG_SIZE_RANGE.cover?(value))
            set_metric(key, value)
          else
            # Encode strings in UTF-8 to facilitate downstream serialization
            meta[Core::Utils.utf8_encode(key)] = Core::Utils.utf8_encode(value)
          end
        rescue StandardError => e
          Datadog.logger.debug("Unable to set the tag #{key}, ignoring it. Caused by: #{e}")
        end

        # Sets tags from given hash, for each key in hash it sets the tag with that key
        # and associated value from the hash. It is shortcut for `set_tag`. Keys and values
        # of the hash must be strings. Note that nested hashes are not supported.
        # A valid example is:
        #
        #   span.set_tags({ "http.method" => "GET", "user.id" => "234" })
        def set_tags(hash)
          hash.each { |k, v| set_tag(k, v) }
        end

        # Returns true if the provided `tag` was set to a non-nil value.
        # False otherwise.
        #
        # @param [String] tag the tag or metric to check for presence
        # @return [Boolean] if the tag is present and not nil
        def has_tag?(tag) # rubocop:disable Naming/PredicateName
          !get_tag(tag).nil? # nil is considered not present, thus we can't use `Hash#has_key?`
        end

        # This method removes a tag for the given key.
        def clear_tag(key)
          meta.delete(key)
        end

        # Convenient interface for setting a single tag.
        alias []= set_tag

        # Convenient interface for getting a single tag.
        alias [] get_tag

        # Return the metric with the given key, nil if it doesn't exist.
        def get_metric(key)
          metrics[key] || meta[key]
        end

        # This method sets a tag with a floating point value for the given key. It acts
        # like `set_tag()` and it simply add a tag without further processing.
        def set_metric(key, value)
          # Keys must be unique between tags and metrics
          meta.delete(key)

          # enforce that the value is a floating point number
          value = Float(value)

          # Encode strings in UTF-8 to facilitate downstream serialization
          metrics[Core::Utils.utf8_encode(key)] = value
        rescue StandardError => e
          Datadog.logger.debug("Unable to set the metric #{key}, ignoring it. Caused by: #{e}")
        end

        # This method removes a metric for the given key. It acts like {#clear_tag}.
        def clear_metric(key)
          metrics.delete(key)
        end

        # Returns a copy of all metadata.
        # Keys for `@meta` and `@metrics` don't collide, by construction.
        def tags
          meta.merge(metrics)
        end

        protected

        def meta
          @meta ||= {}
        end

        def metrics
          @metrics ||= {}
        end
      end
    end
  end
end
