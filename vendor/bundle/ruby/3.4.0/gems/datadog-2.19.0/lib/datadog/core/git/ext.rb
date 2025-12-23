# frozen_string_literal: true

module Datadog
  module Core
    module Git
      # Defines constants for Git tags
      module Ext
        TAG_REPOSITORY_URL = '_dd.git.repository_url'
        TAG_COMMIT_SHA = '_dd.git.commit.sha'

        ENV_REPOSITORY_URL = 'DD_GIT_REPOSITORY_URL'
        ENV_COMMIT_SHA = 'DD_GIT_COMMIT_SHA'
      end
    end
  end
end
