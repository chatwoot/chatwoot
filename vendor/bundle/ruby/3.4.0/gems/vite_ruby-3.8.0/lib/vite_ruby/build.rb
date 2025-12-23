# frozen_string_literal: true

require 'json'
require 'time'

# Internal: Value object with information about the last build.
ViteRuby::Build = Struct.new(:success, :timestamp, :vite_ruby, :digest, :current_digest, :last_build_path, :errors, keyword_init: true) do
  class << self
    # Internal: Combines information from a previous build with the current digest.
    def from_previous(last_build_path, current_digest)
      new(
        **parse_metadata(last_build_path),
        current_digest: current_digest,
        last_build_path: last_build_path,
      )
    end

  private

    # Internal: Reads metadata recorded on the last build, if it exists.
    def parse_metadata(pathname)
      return default_metadata unless pathname.exist?

      JSON.parse(pathname.read.to_s).transform_keys(&:to_sym).slice(*members)
    rescue JSON::JSONError, Errno::ENOENT, Errno::ENOTDIR
      default_metadata
    end

    # Internal: To make it evident that there's no last build in error messages.
    def default_metadata
      { timestamp: 'never', digest: 'none' }
    end
  end

  # Internal: A build is considered stale when watched files have changed since
  # the last build, or when a certain time has ellapsed in case of failure.
  def stale?
    digest != current_digest || retry_failed? || vite_ruby != ViteRuby::VERSION
  end

  # Internal: A build is considered fresh if watched files have not changed, or
  # the last failed build happened recently.
  def fresh?
    !stale?
  end

  # Internal: To avoid cascading build failures, if the last build failed and it
  # happened within a short time window, a new build should not be triggered.
  def retry_failed?
    !success && Time.parse(timestamp) + 3 < Time.now # 3 seconds
  rescue ArgumentError
    true
  end

  # Internal: Returns a new build with the specified result.
  def with_result(**attrs)
    self.class.new(
      **attrs,
      timestamp: Time.now.strftime('%F %T'),
      vite_ruby: ViteRuby::VERSION,
      digest: current_digest,
      current_digest: current_digest,
      last_build_path: last_build_path,
    )
  end

  # Internal: Writes the result of the new build to a local file.
  def write_to_cache
    last_build_path.write to_json
  end

  # Internal: Returns a JSON string with the metadata of the build.
  def to_json(*_args)
    JSON.pretty_generate(
      success: success,
      errors: errors,
      timestamp: timestamp,
      vite_ruby: vite_ruby,
      digest: digest,
    )
  end
end
