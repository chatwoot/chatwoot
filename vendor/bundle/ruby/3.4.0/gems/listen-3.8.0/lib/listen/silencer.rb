# frozen_string_literal: true

module Listen
  class Silencer
    # The default list of directories that get ignored.
    DEFAULT_IGNORED_FILES = %r{\A(?:
    \.git
      | \.svn
      | \.hg
      | \.rbx
      | \.bundle
      | bundle
      | vendor/bundle
      | log
      | tmp
      | vendor/ruby

      # emacs temp files
      | \#.+\#
      | \.\#.+
      )(/|\z)}x.freeze

    # The default list of files that get ignored.
    DEFAULT_IGNORED_EXTENSIONS = %r{(?:
      # Kate's tmp\/swp files
      \..*\d+\.new
      | \.kate-swp

      # Gedit tmp files
      | \.goutputstream-.{6}

      # Intellij files
      | ___jb_bak___
      | ___jb_old___

      # Vim swap files and write test
      | \.sw[px]
      | \.swpx
      | ^4913

      # Sed temporary files - but without actual words, like 'sedatives'
      | (?:\A
         sed

         (?:
          [a-zA-Z0-9]{0}[A-Z]{1}[a-zA-Z0-9]{5} |
          [a-zA-Z0-9]{1}[A-Z]{1}[a-zA-Z0-9]{4} |
          [a-zA-Z0-9]{2}[A-Z]{1}[a-zA-Z0-9]{3} |
          [a-zA-Z0-9]{3}[A-Z]{1}[a-zA-Z0-9]{2} |
          [a-zA-Z0-9]{4}[A-Z]{1}[a-zA-Z0-9]{1} |
          [a-zA-Z0-9]{5}[A-Z]{1}[a-zA-Z0-9]{0}
         )
        )

      # Mutagen sync temporary files
      | \.mutagen-temporary.*

      # other files
      | \.DS_Store
      | \.tmp
      | ~
    )\z}x.freeze

    # TODO: deprecate these mutators; use attr_reader instead
    attr_accessor :only_patterns, :ignore_patterns

    def initialize(**options)
      configure(options)
    end

    # TODO: deprecate this mutator
    def configure(options)
      @only_patterns = options[:only] ? Array(options[:only]) : nil
      @ignore_patterns = _init_ignores(options[:ignore], options[:ignore!])
    end

    def silenced?(relative_path, type)
      path = relative_path.to_s   # in case it is a Pathname

      _ignore?(path) || (only_patterns && type == :file && !_only?(path))
    end

    private

    def _ignore?(path)
      ignore_patterns.any? { |pattern| path =~ pattern }
    end

    def _only?(path)
      only_patterns.any? { |pattern| path =~ pattern }
    end

    def _init_ignores(ignores, overrides)
      patterns = []
      unless overrides
        patterns << DEFAULT_IGNORED_FILES
        patterns << DEFAULT_IGNORED_EXTENSIONS
      end

      patterns << ignores
      patterns << overrides

      patterns.compact.flatten
    end
  end
end
