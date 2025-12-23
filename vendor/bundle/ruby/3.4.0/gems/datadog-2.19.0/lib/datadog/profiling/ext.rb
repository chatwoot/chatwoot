# frozen_string_literal: true

module Datadog
  module Profiling
    module Ext
      ENV_ENABLED = "DD_PROFILING_ENABLED"
      ENV_UPLOAD_TIMEOUT = "DD_PROFILING_UPLOAD_TIMEOUT"
      ENV_MAX_FRAMES = "DD_PROFILING_MAX_FRAMES"
      ENV_AGENTLESS = "DD_PROFILING_AGENTLESS"
      ENV_ENDPOINT_COLLECTION_ENABLED = "DD_PROFILING_ENDPOINT_COLLECTION_ENABLED"

      module Transport
        module HTTP
          FORM_FIELD_TAG_PROFILER_VERSION = "profiler_version"

          CODE_PROVENANCE_FILENAME = "code-provenance.json"
        end
      end
    end
  end
end
