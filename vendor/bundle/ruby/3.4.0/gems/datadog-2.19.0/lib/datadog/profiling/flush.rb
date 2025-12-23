# frozen_string_literal: true

require "json"

module Datadog
  module Profiling
    # Entity class used to represent metadata for a given profile
    class Flush
      attr_reader \
        :start,
        :finish,
        :encoded_profile,
        :code_provenance_file_name,
        :code_provenance_data,
        :tags_as_array,
        :internal_metadata_json,
        :info_json

      def initialize(
        start:,
        finish:,
        encoded_profile:,
        code_provenance_file_name:,
        code_provenance_data:,
        tags_as_array:,
        internal_metadata:,
        info_json:
      )
        @start = start
        @finish = finish
        @encoded_profile = encoded_profile
        @code_provenance_file_name = code_provenance_file_name
        @code_provenance_data = code_provenance_data
        @tags_as_array = tags_as_array
        @internal_metadata_json = JSON.generate(internal_metadata)
        @info_json = info_json
      end
    end
  end
end
