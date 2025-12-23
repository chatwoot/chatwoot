# frozen_string_literal: true

# Internal: Raised when an entry is not found in the build manifest.
#
# NOTE: The complexity here is justified by the improved usability of providing
# a more specific error message depending on the situation.
class ViteRuby::MissingEntrypointError < ViteRuby::Error
  attr_reader :file_name, :last_build, :manifest, :config

  def initialize(file_name:, last_build:, manifest:, config:)
    @file_name, @last_build, @manifest, @config = file_name, last_build, manifest, config
    super <<~MSG
      Vite Ruby can't find #{ file_name } in the manifests.

      Possible causes:
      #{ possible_causes(last_build) }
      :troubleshooting:
      #{ "Manifest files found:\n#{ config.manifest_paths.map { |path| "  #{ path.relative_path_from(config.root) }" }.join("\n") }\n" if last_build.success }
      #{ "Content in your manifests:\n#{ JSON.pretty_generate(manifest) }\n" if last_build.success }
      #{ "Last build in #{ config.mode } mode:\n#{ last_build.to_json }\n" if last_build.success }
    MSG
  end

  def possible_causes(last_build)
    if last_build.success == false
      FAILED_BUILD_CAUSES
        .sub(':mode:', config.mode)
        .sub(':errors:', last_build.errors.to_s.gsub(/^(?!$)/, '  '))
    elsif config.auto_build
      DEFAULT_CAUSES
    else
      DEFAULT_CAUSES + NO_AUTO_BUILD_CAUSES
    end
  end

  FAILED_BUILD_CAUSES = <<~MSG
      - The last build failed. Try running `bin/vite build --clear --mode=:mode:` manually and check for errors.

    Errors:
    :errors:
  MSG

  DEFAULT_CAUSES = <<-MSG
  - The file path is incorrect.
  - The file is not in the entrypoints directory.
  - Some files are outside the sourceCodeDir, and have not been added to watchAdditionalPaths.
  MSG

  NO_AUTO_BUILD_CAUSES = <<-MSG
  - You have not run `bin/vite dev` to start Vite, or the dev server is not reachable.
  - "autoBuild" is set to `false` in your config/vite.json for this environment.
  MSG
end
