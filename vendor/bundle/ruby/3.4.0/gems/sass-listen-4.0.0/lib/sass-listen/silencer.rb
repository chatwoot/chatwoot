module SassListen
  class Silencer
    # The default list of directories that get ignored.
    DEFAULT_IGNORED_DIRECTORIES = %r{^(?:
      \.git
      | \.svn
      | \.hg
      | \.rbx
      | \.bundle
      | bundle
      | vendor/bundle
      | log
      | tmp
      |vendor/ruby
    )(/|$)}x

    # The default list of files that get ignored.
    DEFAULT_IGNORED_EXTENSIONS  = /(?:
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
      | (?:^
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

      # other files
      | \.DS_Store
      | \.tmp
      | ~
    )$/x

    attr_accessor :only_patterns, :ignore_patterns

    def initialize
      configure({})
    end

    def configure(options)
      @only_patterns = options[:only] ? Array(options[:only]) : nil
      @ignore_patterns = _init_ignores(options[:ignore], options[:ignore!])
    end

    # Note: relative_path is temporarily expected to be a relative Pathname to
    # make refactoring easier (ideally, it would take a string)

    # TODO: switch type and path places - and verify
    def silenced?(relative_path, type)
      path = relative_path.to_s

      if only_patterns && type == :file
        return true unless only_patterns.any? { |pattern| path =~ pattern }
      end

      ignore_patterns.any? { |pattern| path =~ pattern }
    end

    private

    attr_reader :options

    def _init_ignores(ignores, overrides)
      patterns = []
      unless overrides
        patterns << DEFAULT_IGNORED_DIRECTORIES
        patterns << DEFAULT_IGNORED_EXTENSIONS
      end

      patterns << ignores
      patterns << overrides

      patterns.compact.flatten
    end
  end
end
