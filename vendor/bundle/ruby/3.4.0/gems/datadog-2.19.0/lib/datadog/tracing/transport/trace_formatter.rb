# frozen_string_literal: true

require_relative '../../core/environment/identity'
require_relative '../../core/environment/socket'
require_relative '../../core/environment/git'
require_relative '../../core/git/ext'
require_relative '../../core/runtime/ext'
require_relative '../metadata/ext'
require_relative '../trace_segment'

module Datadog
  module Tracing
    module Transport
      # Prepares traces for transport
      class TraceFormatter
        attr_reader \
          :root_span,
          :first_span,
          :trace

        def self.format!(trace)
          new(trace).format!
        end

        def initialize(trace)
          @trace = trace
          @root_span = find_root_span(trace)
          # source code integration uses the "first span in trace chunk" concept instead of root span
          # see: https://github.com/DataDog/dd-trace-rb/pull/3424
          @first_span = trace.spans.first
        end

        # Modifies a trace so suitable for transport
        def format!
          return unless trace
          return trace unless root_span

          # Because the trace API does not support
          # trace metadata, we must put our trace
          # metadata on the root span. This "root span"
          # is needed by the agent/API to ingest the trace.

          # Apply generic trace tags. Any more specific value will be overridden
          # by the subsequent calls below.
          set_trace_tags!

          set_resource!

          tag_agent_sample_rate!
          tag_hostname!
          tag_lang!
          tag_origin!
          tag_process_id!
          tag_rule_sample_rate!
          tag_runtime_id!
          tag_rate_limiter_rate!
          tag_sample_rate!
          tag_sampling_decision_maker!
          tag_high_order_trace_id!
          tag_sampling_priority!
          tag_profiling_enabled!
          tag_apm_tracing_disabled!

          if first_span
            tag_git_repository_url!
            tag_git_commit_sha!
          end

          trace
        end

        protected

        def set_resource!
          # If the trace resource is undefined, or the root span wasn't
          # specified, don't set this. We don't want to overwrite the
          # resource of a span that is in the middle of the trace.
          return if trace.resource.nil? || partial?

          root_span.resource = trace.resource
        end

        def set_trace_tags!
          # If the root span wasn't specified, don't set this. We don't want to
          # misset or overwrite the tags of a span that is in the middle of the
          # trace.
          return if partial?

          root_span.set_tags(trace.send(:meta))
          root_span.set_tags(trace.send(:metrics))
        end

        def tag_agent_sample_rate!
          return unless trace.agent_sample_rate

          root_span.set_tag(
            Tracing::Metadata::Ext::Sampling::TAG_AGENT_RATE,
            trace.agent_sample_rate
          )
        end

        def tag_hostname!
          return unless trace.hostname

          root_span.set_tag(
            Tracing::Metadata::Ext::NET::TAG_HOSTNAME,
            trace.hostname
          )
        end

        def tag_lang!
          return if trace.lang.nil?

          root_span.set_tag(
            Core::Runtime::Ext::TAG_LANG,
            trace.lang
          )
        end

        def tag_origin!
          return unless trace.origin

          root_span.set_tag(
            Tracing::Metadata::Ext::Distributed::TAG_ORIGIN,
            trace.origin
          )
        end

        def tag_process_id!
          return unless trace.process_id

          root_span.set_tag(Core::Runtime::Ext::TAG_PROCESS_ID, trace.process_id)
        end

        def tag_rate_limiter_rate!
          return unless trace.rate_limiter_rate

          root_span.set_tag(
            Tracing::Metadata::Ext::Sampling::TAG_RATE_LIMITER_RATE,
            trace.rate_limiter_rate
          )
        end

        def tag_rule_sample_rate!
          return unless trace.rule_sample_rate

          root_span.set_tag(
            Tracing::Metadata::Ext::Sampling::TAG_RULE_SAMPLE_RATE,
            trace.rule_sample_rate
          )
        end

        def tag_runtime_id!
          return unless trace.runtime_id

          root_span.set_tag(
            Core::Runtime::Ext::TAG_ID,
            trace.runtime_id
          )
        end

        def tag_sample_rate!
          return unless trace.sample_rate

          root_span.set_tag(
            Tracing::Metadata::Ext::Sampling::TAG_SAMPLE_RATE,
            trace.sample_rate
          )
        end

        def tag_sampling_decision_maker!
          return unless (decision = trace.sampling_decision_maker)

          root_span.set_tag(Tracing::Metadata::Ext::Distributed::TAG_DECISION_MAKER, decision)
        end

        def tag_sampling_priority!
          return unless trace.sampling_priority

          root_span.set_metric(
            Tracing::Metadata::Ext::Distributed::TAG_SAMPLING_PRIORITY,
            trace.sampling_priority
          )
        end

        def tag_high_order_trace_id!
          return unless (high_order_tid = trace.high_order_tid)

          root_span.set_tag(Tracing::Metadata::Ext::Distributed::TAG_TID, high_order_tid)
        end

        def tag_profiling_enabled!
          return if trace.profiling_enabled.nil?

          root_span.set_tag(
            Tracing::Metadata::Ext::TAG_PROFILING_ENABLED, trace.profiling_enabled ? 1 : 0
          )
        end

        def tag_apm_tracing_disabled!
          return if trace.apm_tracing_enabled

          root_span.set_tag(Tracing::Metadata::Ext::TAG_APM_ENABLED, 0)
        end

        def tag_git_repository_url!
          return if git_repository_url.nil?

          first_span.set_tag(Core::Git::Ext::TAG_REPOSITORY_URL, git_repository_url)
        end

        def tag_git_commit_sha!
          return if git_commit_sha.nil?

          first_span.set_tag(Core::Git::Ext::TAG_COMMIT_SHA, git_commit_sha)
        end

        private

        def partial?
          !@found_root_span
        end

        def find_root_span(trace)
          # TODO: Should we memoize this?
          #       Would be safe, but `spans` is mutable, so if
          #       the root span were removed, it would be a stale reference.
          #       Figure out a better way to deal with this.
          root_span_id = trace.send(:root_span_id)
          root_span = trace.spans.find { |s| s.id == root_span_id } if root_span_id
          @found_root_span = !root_span.nil?

          # when root span is not found, fall back to last span (partial flush)
          root_span || trace.spans.last
        end

        def git_repository_url
          Core::Environment::Git.git_repository_url
        end

        def git_commit_sha
          Core::Environment::Git.git_commit_sha
        end
      end
    end
  end
end
