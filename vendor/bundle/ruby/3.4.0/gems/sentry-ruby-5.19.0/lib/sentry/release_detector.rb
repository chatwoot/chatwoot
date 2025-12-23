# frozen_string_literal: true

module Sentry
  # @api private
  class ReleaseDetector
    class << self
      def detect_release(project_root:, running_on_heroku:)
        detect_release_from_env ||
        detect_release_from_git ||
        detect_release_from_capistrano(project_root) ||
        detect_release_from_heroku(running_on_heroku)
      end

      def detect_release_from_heroku(running_on_heroku)
        return unless running_on_heroku
        ENV['HEROKU_SLUG_COMMIT']
      end

      def detect_release_from_capistrano(project_root)
        revision_file = File.join(project_root, 'REVISION')
        revision_log = File.join(project_root, '..', 'revisions.log')

        if File.exist?(revision_file)
          File.read(revision_file).strip
        elsif File.exist?(revision_log)
          File.open(revision_log).to_a.last.strip.sub(/.*as release ([0-9]+).*/, '\1')
        end
      end

      def detect_release_from_git
        Sentry.sys_command("git rev-parse HEAD") if File.directory?(".git")
      end

      def detect_release_from_env
        ENV['SENTRY_RELEASE']
      end
    end
  end
end
