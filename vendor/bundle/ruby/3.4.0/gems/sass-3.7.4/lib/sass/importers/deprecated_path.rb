module Sass
  module Importers
    # This importer emits a deprecation warning the first time it is used to
    # import a file. It is used to deprecate the current working
    # directory from the list of automatic sass load paths.
    class DeprecatedPath < Filesystem
      # @param root [String] The absolute, expanded path to the folder that is deprecated.
      def initialize(root)
        @specified_root = root
        @warning_given = false
        super
      end

      # @see Sass::Importers::Base#find
      def find(*args)
        found = super
        if found && !@warning_given
          @warning_given = true
          Sass::Util.sass_warn deprecation_warning
        end
        found
      end

      # @see Base#directories_to_watch
      def directories_to_watch
        # The current working directory was not watched in Sass 3.2,
        # so we continue not to watch it while it's deprecated.
        []
      end

      # @see Sass::Importers::Base#to_s
      def to_s
        "#{@root} (DEPRECATED)"
      end

      protected

      # @return [String] The deprecation warning that will be printed the first
      #   time an import occurs.
      def deprecation_warning
        path = @specified_root == "." ? "the current working directory" : @specified_root
        <<WARNING
DEPRECATION WARNING: Importing from #{path} will not be
automatic in future versions of Sass.  To avoid future errors, you can add it
to your environment explicitly by setting `SASS_PATH=#{@specified_root}`, by using the -I command
line option, or by changing your Sass configuration options.
WARNING
      end
    end
  end
end
