# frozen_string_literal: true

require_relative "ext"
require_relative "tag_builder"

module Datadog
  module Profiling
    # Exports profiling data gathered by the multiple recorders in a `Flush`.
    #
    # @ivoanjo: Note that the recorder that gathers pprof data is special, since we use its start/finish/empty? to
    # decide if there's data to flush, as well as the timestamp for that data.
    # I could've made the whole design more generic, but I'm unsure if we'll ever have more than a handful of
    # recorders, so I've decided to make it specific until we actually need to support more recorders.
    #
    class Exporter
      # Profiles with duration less than this will not be reported
      PROFILE_DURATION_THRESHOLD_SECONDS = 1

      private

      attr_reader \
        :pprof_recorder,
        :code_provenance_collector, # The code provenance collector acts both as collector and as a recorder
        :minimum_duration_seconds,
        :time_provider,
        :last_flush_finish_at,
        :created_at,
        :internal_metadata,
        :info_json,
        :sequence_tracker

      public

      def initialize(
        pprof_recorder:,
        worker:,
        info_collector:,
        code_provenance_collector:,
        internal_metadata:,
        minimum_duration_seconds: PROFILE_DURATION_THRESHOLD_SECONDS,
        time_provider: Time,
        sequence_tracker: Datadog::Profiling::SequenceTracker
      )
        @pprof_recorder = pprof_recorder
        @worker = worker
        @code_provenance_collector = code_provenance_collector
        @minimum_duration_seconds = minimum_duration_seconds
        @time_provider = time_provider
        @last_flush_finish_at = nil
        @created_at = time_provider.now.utc
        @internal_metadata = internal_metadata
        # NOTE: At the time of this comment collected info does not change over time so we'll hardcode
        #       it on startup to prevent serializing the same info on every flush.
        @info_json = JSON.generate(info_collector.info).freeze
        @sequence_tracker = sequence_tracker
      end

      def flush
        worker_stats = @worker.stats_and_reset_not_thread_safe
        serialization_result = pprof_recorder.serialize
        return if serialization_result.nil?

        start, finish, encoded_profile, profile_stats = serialization_result
        @last_flush_finish_at = finish

        if duration_below_threshold?(start, finish)
          Datadog.logger.debug("Skipped exporting profiling events as profile duration is below minimum")
          return
        end

        uncompressed_code_provenance = code_provenance_collector.refresh.generate_json if code_provenance_collector

        Flush.new(
          start: start,
          finish: finish,
          encoded_profile: encoded_profile,
          code_provenance_file_name: Datadog::Profiling::Ext::Transport::HTTP::CODE_PROVENANCE_FILENAME,
          code_provenance_data: uncompressed_code_provenance,
          tags_as_array: Datadog::Profiling::TagBuilder.call(
            settings: Datadog.configuration,
            profile_seq: sequence_tracker.get_next,
          ).to_a,
          internal_metadata: internal_metadata.merge(
            {
              worker_stats: worker_stats,
              profile_stats: profile_stats,
              recorder_stats: pprof_recorder.stats,
              gc: GC.stat,
            }
          ),
          info_json: info_json,
        )
      end

      def can_flush?
        !duration_below_threshold?(last_flush_finish_at || created_at, time_provider.now.utc)
      end

      def reset_after_fork
        @last_flush_finish_at = time_provider.now.utc
        nil
      end

      private

      def duration_below_threshold?(start, finish)
        (finish - start) < minimum_duration_seconds
      end
    end
  end
end
