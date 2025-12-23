# frozen_string_literal: true

# standard gets itself into an infinite loop over this
# rubocop:disable Layout/SpaceAfterNot

module Datadog
  module DI
    module Utils
      # General path matching considerations
      # ------------------------------------
      #
      # The following use cases must be supported:
      # 1. The "probe path" is relative path to the file from source code
      #    repository root. The project is deployed from the repository root,
      #    such that that same relative path exists at runtime from the
      #    root of the application.
      # 2. The "probe path" is a relative path to the file in a monorepo
      #    where the project being deployed is in a subdirectory.
      #    This the "probe path" contains additional directory components
      #    in the beginning that do not exist in the runtime environment.
      # 3. The "probe path" is an absolute path to the file on the customer's
      #    development system. As specified this path definitely does not
      #    exist at runtime, and can start with a prefix that is unknown
      #    to any both UI and tracer code.
      # 4. Same as (3), but the customer is using a Windows computer for
      #    development and has the path specified in the wrong case
      #    (which works fine on their development machine).
      # 5. The "probe path" is the basename or any suffix of the path to
      #    the desired file, typed manually by the customer into the UI.
      #
      # A related concern is that if multiple runtime paths match the path
      # specification in the probe, the tracer must return an error to the
      # backend/UI rather than instrumenting any of the matching paths.
      #
      # The logic for path matching should therefore, generally, be as follows:
      # 1. If the "probe path" is absolute, see if it exists at runtime.
      #    If so, take it as the desired path and finish.
      # 2. Attempt to identify the application root, by checking if the current
      #    working directory contains a file called Gemfile. If yes, assume
      #    the current working directory is the application root, otherwise
      #    consider the application root to be unknown.
      # 3. If the application root is known and the "probe path" is relative,
      #    concatenate the "probe path" to the application root and check
      #    if the resulting path exists at runtime. If so, take it as the
      #    desired path and finish.
      # 4. If the "probe path" is relative, go through the known file paths,
      #    filter these paths down to those whose suffix is the "probe path",
      #    and check how many we are left with. If exactly one, assume this
      #    is the desired path and finish. If more than one, return an error
      #    "multiple matching paths".
      # 5. If the application root is known, for each suffix of the "probe path",
      #    see if that relative paths concatenated to the application root
      #    results in a known file. If a known file is found, assume this
      #    is the wanted file and finish.
      # 6. For each suffix of the "probe path", filter the set of known paths
      #    down to those that end in the suffix. If exactly one path remains
      #    for a given suffix, assume this is the wanted path and finish.
      #    If more than one path remains for a given suffix, return the error
      #    "multiple matching paths".
      # 7. Repeat step 5 but perform case-insensitive comparison.
      # 8. Repeat step 6 but perform case-insensitive comparison.
      #
      # Note that we do not look for "probe paths" under the current working
      # directory at runtime if the current working directory does not contain
      # a Gemfile, to avoid finding files from potentially undesired bases.
      #
      # What "known file"/"known path" means also differs based on the
      # operation being performed:
      # - If the operation is "install a probe", "known file/path" can
      #   include files on the filesystem that have not been loaded as
      #   well as paths from the code tracker.
      # - If the operation is "check if any pending probes match the file
      #   that was just loaded", we would only consider the path that was
      #   just loaded and not check the filesystem.
      #
      # Filesystem inquiries are obviously quite expensive and should be
      # cached. For the vast majority of applications it should be safe to
      # indefinitely cache whether a particular filesystem paths exists
      # in both positive and negative.
      #
      # As a "quick fix", currently after performing the suffix matching
      # we just strip leading directory components from the "probe path"
      # until we get a match via a "suffix of the suffix".

      # Returns whether the provided +path+ matches the user-designated
      # file suffix (of a line probe).
      #
      # If suffix is an absolute path (i.e., it starts with a slash), the path
      # must be identical for it to match.
      #
      # If suffix is not an absolute path, the path matches if its suffix is
      # the provided suffix, at a path component boundary.
      module_function def path_matches_suffix?(path, suffix)
        if path.nil?
          raise ArgumentError, "nil path passed"
        end
        if suffix.nil?
          raise ArgumentError, "nil suffix passed"
        end

        if suffix.start_with?('/')
          path == suffix
        else
          # Exact match is not possible here, meaning any matching path
          # has to be longer than the suffix. Require full component matches,
          # meaning either the first character of the suffix is a slash
          # or the previous character in the path is a slash.
          # For now only check for forward slashes for Unix-like OSes;
          # backslash is a legitimate character of a file name in Unix
          # therefore simply permitting forward or back slash is not
          # sufficient, we need to perform an OS check to know which
          # path separator to use.
          !!
          if path.length > suffix.length && path.end_with?(suffix)
            previous_char = path[path.length - suffix.length - 1]
            previous_char == "/" || suffix[0] == "/"
          end

          # Alternative implementation using a regular expression:
          # !!(path =~ %r,(/|\A)#{Regexp.quote(suffix)}\z,)
        end
      end

      # Returns whether the provided +path+ matches the "probe path" in
      # +spec+. Attempts all of the fuzzy matches by stripping directories
      # from the front of +spec+. Does not consider othr known paths to
      # identify the case of (potentially) multiple matching paths for +spec+.
      module_function def path_can_match_spec?(path, spec)
        return true if path_matches_suffix?(path, spec)

        spec = spec.dup
        loop do
          return false unless spec.include?('/')
          spec.sub!(%r{.*/+}, '')
          return true if path_matches_suffix?(path, spec)
        end
      end
    end
  end
end

# rubocop:enable Layout/SpaceAfterNot
