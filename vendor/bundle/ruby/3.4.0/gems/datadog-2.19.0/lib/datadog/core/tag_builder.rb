# frozen_string_literal: true

require_relative 'environment/socket'
require_relative 'environment/identity'
require_relative 'environment/git'

module Datadog
  module Core
    # This module builds a hash of tags.
    #
    # When changing or adding the tags, make sure they are kept in sync with
    # https://docs.google.com/spreadsheets/d/1LOGMf4c4Avbtn36uZ2SWvhIGKRPLM1BoWkUP4JYj7hA/
    # (Datadog internal link).
    #
    # @api private
    module TagBuilder
      def self.fixed_environment_tags
        @fixed_environment_tags ||= {
          'language' => Environment::Identity.lang,
          'runtime' => Environment::Identity.lang, # Known to be duplicated from language above
          'runtime_engine' => Environment::Identity.lang_engine,
          'runtime_platform' => Environment::Identity.lang_platform,
          'runtime_version' => Environment::Identity.lang_version,
          'library_version' => Environment::Identity.gem_datadog_version,
          'git.repository_url' => Environment::Git.git_repository_url,
          'git.commit.sha' => Environment::Git.git_commit_sha,
        }.compact.freeze
      end

      def self.tags(settings)
        # Note that user tags get overwritten by our tags, and also
        # that user tags do not get compacted (nil values are sent as
        # empty strings).
        settings.tags.merge(fixed_environment_tags).merge({
          # Hostname can possibly change during application runtime.
          'host' => Environment::Socket.hostname,
          # Runtime ID changes upon a fork.
          'runtime-id' => Environment::Identity.id,
          # Process ID changes upon a fork.
          'process_id' => Process.pid.to_s,
          # Unified service tagging.
          'env' => settings.env,
          'service' => settings.service,
          'version' => settings.version,
        }.compact)
      end

      def self.serialize_tags(tags)
        # DEV: Should there be some sort of escaping done here?
        tags.map do |key, value|
          "#{key}:#{value}"
        end.join(',')
      end
    end
  end
end
