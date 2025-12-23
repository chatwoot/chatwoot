# frozen_string_literal: true

require_relative "../core/tag_builder"
require_relative "../core/utils"

module Datadog
  module Profiling
    # Builds a hash of default plus user tags to be included in a profile
    module TagBuilder
      include Datadog::Profiling::Ext::Transport::HTTP # Tag name constants

      def self.call(
        settings:,
        # Other metadata
        profile_seq:,
        profiler_version: Core::Environment::Identity.gem_datadog_version
      )
        hash = Core::TagBuilder.tags(settings).merge(
          FORM_FIELD_TAG_PROFILER_VERSION => profiler_version,
          'profile_seq' => profile_seq.to_s,
        )
        Core::Utils.encode_tags(hash)
      end
    end
  end
end
