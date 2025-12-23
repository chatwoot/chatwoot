require "optparse"

module AnnotateRb
  # Class for handling command line arguments
  class Parser # rubocop:disable Metrics/ClassLength
    def self.parse(args, existing_options)
      new(args, existing_options).parse
    end

    BANNER_STRING = <<~BANNER.freeze
      Usage: annotaterb [command] [options]

      Commands:
          models [options]
          routes [options]
          help
          version
    BANNER

    DEFAULT_OPTIONS = {
      target_action: :do_annotations,
      exit: false
    }.freeze

    ANNOTATION_POSITIONS = %w[before top after bottom].freeze
    FILE_TYPE_POSITIONS = %w[position_in_class position_in_factory position_in_fixture position_in_test position_in_routes position_in_serializer].freeze
    EXCLUSION_LIST = %w[tests fixtures factories serializers].freeze
    FORMAT_TYPES = %w[bare rdoc yard markdown].freeze

    COMMAND_MAP = {
      "models" => :models,
      "routes" => :routes,
      "version" => :version,
      "help" => :help
    }.freeze

    def initialize(args, existing_options)
      @args = args.clone
      base_options = DEFAULT_OPTIONS.dup
      @options = base_options.merge(existing_options)
      @commands = []
      @options[:original_args] = args.clone
    end

    def parse
      parse_command(@args)

      parser.parse!(@args)

      act_on_command

      @options
    end

    def remaining_args
      # `@args` gets modified throughout the lifecycle of this class.
      # It starts as a shallow clone of ARGV, then arguments matching commands and options are removed in #parse
      @args
    end

    private

    def parse_command(args)
      command_arg = args.first
      command = COMMAND_MAP[command_arg]

      if command
        args.shift
        @commands << command
      end
    end

    def act_on_command
      map = {
        models: Commands::AnnotateModels.new,
        routes: Commands::AnnotateRoutes.new,
        help: Commands::PrintHelp.new(@parser),
        version: Commands::PrintVersion.new
      }

      if @commands.size > 1
        warn "Only one command can be run at a time"
      end

      @options[:command] = if @commands.any?
        map[@commands.first]
      else # None
        map[:help]
      end
    end

    def parser
      @parser ||= OptionParser.new do |option_parser|
        option_parser.banner = BANNER_STRING

        # ------------------------------------------------------------------------------------------------------------=
        option_parser.separator("")
        option_parser.separator("Options:")

        option_parser.on("-v", "--version", "Display the version..") do
          @commands << :version
        end

        option_parser.on("-h", "--help", "You're looking at it.") do
          @commands << :help
        end

        add_model_options_to_parser(option_parser)
        add_route_options_to_parser(option_parser)
        add_wrapper_options_to_parser(option_parser)
        add_options_to_parser(option_parser)
        add_position_options_to_parser(option_parser)
        add_utils_to_parser(option_parser)
      end
    end

    def add_wrapper_options_to_parser(option_parser)
      option_parser.on("--w",
        "--wrapper STR",
        "Wrap annotation with the text passed as parameter.",
        "If --w option is used, the same text will be used as opening and closing") do |wrapper|
        @options[:wrapper] = wrapper
      end

      option_parser.on("--wo",
        "--wrapper-open STR",
        "Annotation wrapper opening.") do |wrapper_open|
        @options[:wrapper_open] = wrapper_open
      end

      option_parser.on("--wc",
        "--wrapper-close STR",
        "Annotation wrapper closing") do |wrapper_close|
        @options[:wrapper_close] = wrapper_close
      end
    end

    def add_utils_to_parser(option_parser)
      option_parser.on("--force",
        "Force new annotations even if there are no changes.") do
        @options[:force] = true
      end

      option_parser.on("--debug",
        "Prints the options and outputs messages to make it easier to debug.") do
        @options[:debug] = true
      end

      option_parser.on("--frozen",
        "Do not allow to change annotations. Exits non-zero if there are going to be changes to files.") do
        @options[:frozen] = true
      end

      option_parser.on("--trace",
        "If unable to annotate a file, print the full stack trace, not just the exception message.") do
        @options[:trace] = true
      end
    end

    def add_model_options_to_parser(option_parser)
      option_parser.separator("")
      option_parser.separator("Annotate model options:")
      option_parser.separator(" " * 4 + "Usage: annotaterb models [options]")
      option_parser.separator("")

      option_parser.on("-a",
        "--active-admin",
        "Annotate active_admin models") do
        @options[:active_admin] = true
      end

      option_parser.on("--show-migration",
        "Include the migration version number in the annotation") do
        @options[:include_version] = true
      end

      option_parser.on("-k",
        "--show-foreign-keys",
        "List the table's foreign key constraints in the annotation") do
        @options[:show_foreign_keys] = true
      end

      option_parser.on("--ck",
        "--complete-foreign-keys",
        "Complete foreign key names in the annotation") do
        @options[:show_foreign_keys] = true
        @options[:show_complete_foreign_keys] = true
      end

      option_parser.on("-i",
        "--show-indexes",
        "List the table's database indexes in the annotation") do
        @options[:show_indexes] = true
      end

      option_parser.on("-s",
        "--simple-indexes",
        "Concat the column's related indexes in the annotation") do
        @options[:simple_indexes] = true
      end

      option_parser.on("-c",
        "--show-check-constraints",
        "List the table's check constraints in the annotation") do
        @options[:show_check_constraints] = true
      end

      option_parser.on("--hide-limit-column-types VALUES",
        "don't show limit for given column types, separated by commas (i.e., `integer,boolean,text`)") do |values|
        @options[:hide_limit_column_types] = values.to_s
      end

      option_parser.on("--hide-default-column-types VALUES",
        "don't show default for given column types, separated by commas (i.e., `json,jsonb,hstore`)") do |values|
        @options[:hide_default_column_types] = values.to_s
      end

      option_parser.on("--ignore-unknown-models",
        "don't display warnings for bad model files") do
        @options[:ignore_unknown_models] = true
      end

      option_parser.on("-I",
        "--ignore-columns REGEX",
        "don't annotate columns that match a given REGEX (i.e., `annotate -I '^(id|updated_at|created_at)'`") do |regex|
        @options[:ignore_columns] = regex
      end

      option_parser.on("--with-comment",
        "include database comments in model annotations") do
        @options[:with_comment] = true
      end

      option_parser.on("--without-comment",
        "include database comments in model annotations") do
        @options[:with_comment] = false
      end

      option_parser.on("--with-column-comments",
        "include column comments in model annotations") do
        @options[:with_column_comments] = true
      end

      option_parser.on("--without-column-comments",
        "exclude column comments in model annotations") do
        @options[:with_column_comments] = false
      end

      option_parser.on("--position-of-column-comment [with_name|rightmost_column]",
        "set the position, in the annotation block, of the column comment") do |value|
        @options[:position_of_column_comment] = value.to_sym
      end

      option_parser.on("--with-table-comments",
        "include table comments in model annotations") do
        @options[:with_table_comments] = true
      end

      option_parser.on("--without-table-comments",
        "exclude table comments in model annotations") do
        @options[:with_table_comments] = false
      end

      option_parser.on("--classes-default-to-s class",
        "Custom classes to be represented with `to_s`, may be used multiple times") do |klass|
        @options[:classes_default_to_s] = if @options[:classes_default_to_s].present?
          [*@options[:classes_default_to_s], klass]
        else
          [klass]
        end
      end

      option_parser.on("--nested-position",
        "Place annotations directly above nested classes or modules instead of at the top of the file.") do
        @options[:nested_position] = true
      end
    end

    def add_route_options_to_parser(option_parser)
      option_parser.separator("")
      option_parser.separator("Annotate routes options:")
      option_parser.separator(" " * 4 + "Usage: annotaterb routes [options]")
      option_parser.separator("")

      option_parser.on("--ignore-routes REGEX",
        "don't annotate routes that match a given REGEX (i.e., `annotate -I '(mobile|resque|pghero)'`") do |regex|
        @options[:ignore_routes] = regex
      end

      option_parser.on("--timestamp",
        "Include timestamp in (routes) annotation") do
        @options[:timestamp] = true
      end
    end

    def add_position_options_to_parser(option_parser)
      has_set_position = {}

      option_parser.on("-p",
        "--position [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of the model/test/fixture/factory/route/serializer file(s)") do |position|
        @options[:position] = position

        FILE_TYPE_POSITIONS.each do |key|
          @options[key.to_sym] = position unless has_set_position[key]
        end
      end

      option_parser.on("--pc",
        "--position-in-class [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of the model file") do |position_in_class|
        @options[:position_in_class] = position_in_class
        has_set_position["position_in_class"] = true
      end

      option_parser.on("--pf",
        "--position-in-factory [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of any factory files") do |position_in_factory|
        @options[:position_in_factory] = position_in_factory
        has_set_position["position_in_factory"] = true
      end

      option_parser.on("--px",
        "--position-in-fixture [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of any fixture files") do |position_in_fixture|
        @options[:position_in_fixture] = position_in_fixture
        has_set_position["position_in_fixture"] = true
      end

      option_parser.on("--pt",
        "--position-in-test [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of any test files") do |position_in_test|
        @options[:position_in_test] = position_in_test
        has_set_position["position_in_test"] = true
      end

      option_parser.on("--pr",
        "--position-in-routes [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of the routes.rb file") do |position_in_routes|
        @options[:position_in_routes] = position_in_routes
        has_set_position["position_in_routes"] = true
      end

      option_parser.on("--ps",
        "--position-in-serializer [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of the serializer files") do |position_in_serializer|
        @options[:position_in_serializer] = position_in_serializer
        has_set_position["position_in_serializer"] = true
      end

      option_parser.on("--pa",
        "--position-in-additional-file-patterns [before|top|after|bottom]",
        ANNOTATION_POSITIONS,
        "Place the annotations at the top (before) or the bottom (after) of files captured in additional file patterns") do |position_in_serializer|
        @options[:position_in_additional_file_patterns] = position_in_serializer
        has_set_position["position_in_additional_file_patterns"] = true
      end
    end

    def add_options_to_parser(option_parser) # rubocop:disable Metrics/MethodLength
      option_parser.separator("")
      option_parser.separator("Command options:")
      option_parser.separator("Additional options that work for annotating models and routes")
      option_parser.separator("")

      option_parser.on("--additional-file-patterns path1,path2,path3",
        Array,
        "Additional file paths or globs to annotate, separated by commas (e.g. `/foo/bar/%MODEL_NAME%/*.rb,/baz/%MODEL_NAME%.rb`)") do |additional_file_patterns|
        @options[:additional_file_patterns] = additional_file_patterns
      end

      option_parser.on("-d",
        "--delete",
        "Remove annotations from all model files or the routes.rb file") do
        @options[:target_action] = :remove_annotations
      end

      option_parser.on("--model-dir dir",
        "Annotate model files stored in dir rather than app/models, separate multiple dirs with commas") do |dir|
        @options[:model_dir] = dir
      end

      option_parser.on("--root-dir dir",
        "Annotate files stored within root dir projects, separate multiple dirs with commas") do |dir|
        @options[:root_dir] = dir
      end

      option_parser.on("--ignore-model-subdirects",
        "Ignore subdirectories of the models directory") do
        @options[:ignore_model_sub_dir] = true
      end

      option_parser.on("--sort",
        "Sort columns alphabetically, rather than in creation order") do
        @options[:sort] = true
      end

      option_parser.on("--classified-sort",
        "Sort columns alphabetically, but first goes id, then the rest columns, then the timestamp columns and then the association columns") do
        @options[:classified_sort] = true
      end

      option_parser.on("--grouped-polymorphic",
        "Group polymorphic associations together in the annotation when using --classified-sort") do
        @options[:grouped_polymorphic] = true
      end

      option_parser.on("-R",
        "--require path",
        "Additional file to require before loading models, may be used multiple times") do |path|
        @options[:require] = if @options[:require].present?
          [@options[:require], path].join(",")
        else
          path
        end
      end

      option_parser.on("-e",
        "--exclude [tests,fixtures,factories,serializers,sti_subclasses]",
        Array,
        "Do not annotate fixtures, test files, factories, serializers, and/or sti subclasses") do |exclusions|
        exclusions ||= EXCLUSION_LIST
        exclusions.each { |exclusion| @options["exclude_#{exclusion}".to_sym] = true }
      end

      option_parser.on("-f",
        "--format [bare|rdoc|yard|markdown]",
        FORMAT_TYPES,
        "Render Schema Information as plain/RDoc/Yard/Markdown") do |format_type|
        @options["format_#{format_type}".to_sym] = true
      end
    end
  end
end
