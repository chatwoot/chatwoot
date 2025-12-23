# frozen_string_literal: true

require_relative '../git/ext'
require_relative '../utils/url'

module Datadog
  module Core
    # Environment
    module Environment
      # Retrieves git repository information from environment variables
      module Git
        def self.git_repository_url
          return @git_repository_url if defined?(@git_repository_url)

          @git_repository_url = Utils::Url.filter_basic_auth(ENV[Datadog::Core::Git::Ext::ENV_REPOSITORY_URL])
        end

        def self.git_commit_sha
          return @git_commit_sha if defined?(@git_commit_sha)

          @git_commit_sha = ENV[Datadog::Core::Git::Ext::ENV_COMMIT_SHA]
        end
      end
    end
  end
end
