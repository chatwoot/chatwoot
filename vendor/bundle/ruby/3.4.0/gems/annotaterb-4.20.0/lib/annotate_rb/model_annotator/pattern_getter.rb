# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    class PatternGetter
      module FilePatterns
        # Controller files
        CONTROLLER_DIR = File.join("app", "controllers")

        # Active admin registry files
        ACTIVEADMIN_DIR = File.join("app", "admin")

        # Helper files
        HELPER_DIR = File.join("app", "helpers")

        # File.join for windows reverse bar compat?
        # I dont use windows, can`t test
        UNIT_TEST_DIR = File.join("test", "unit")
        MODEL_TEST_DIR = File.join("test", "models") # since rails 4.0
        SPEC_MODEL_DIR = File.join("spec", "models")

        FIXTURE_TEST_DIR = File.join("test", "fixtures")
        FIXTURE_SPEC_DIR = File.join("spec", "fixtures")

        # Other test files
        CONTROLLER_TEST_DIR = File.join("test", "controllers")
        CONTROLLER_SPEC_DIR = File.join("spec", "controllers")
        REQUEST_SPEC_DIR = File.join("spec", "requests")
        ROUTING_SPEC_DIR = File.join("spec", "routing")

        # Object Daddy http://github.com/flogic/object_daddy/tree/master
        EXEMPLARS_TEST_DIR = File.join("test", "exemplars")
        EXEMPLARS_SPEC_DIR = File.join("spec", "exemplars")

        # Machinist http://github.com/notahat/machinist
        BLUEPRINTS_TEST_DIR = File.join("test", "blueprints")
        BLUEPRINTS_SPEC_DIR = File.join("spec", "blueprints")

        # Factory Bot https://github.com/thoughtbot/factory_bot
        FACTORY_BOT_TEST_DIR = File.join("test", "factories")
        FACTORY_BOT_SPEC_DIR = File.join("spec", "factories")

        # Fabrication https://github.com/paulelliott/fabrication.git
        FABRICATORS_TEST_DIR = File.join("test", "fabricators")
        FABRICATORS_SPEC_DIR = File.join("spec", "fabricators")

        # Serializers https://github.com/rails-api/active_model_serializers
        SERIALIZERS_DIR = File.join("app", "serializers")
        SERIALIZERS_TEST_DIR = File.join("test", "serializers")
        SERIALIZERS_SPEC_DIR = File.join("spec", "serializers")
      end

      class << self
        def call(options, pattern_types = [])
          new(options, pattern_types).get
        end
      end

      def initialize(options, pattern_types = [])
        @options = options
        @pattern_types = pattern_types
      end

      def get
        current_patterns = []

        root_dirs = @options[:root_dir].flat_map do |root_dir|
          root_dir.empty? ? root_dir : Dir[root_dir]
        end
        root_dirs.each do |root_directory|
          Array(@pattern_types).each do |pattern_type|
            patterns = generate(root_directory, pattern_type)

            current_patterns += if pattern_type.to_sym == :additional_file_patterns
              patterns
            else
              patterns.map { |p| p.sub(/^\/*/, "") }
            end
          end
        end

        current_patterns
      end

      private

      def generate(root_directory, pattern_type)
        case pattern_type
        when "test" then test_files(root_directory)
        when "fixture" then fixture_files(root_directory)
        when "scaffold" then scaffold_files(root_directory)
        when "factory" then factory_files(root_directory)
        when "serializer" then serialize_files(root_directory)
        when "serializer_test" then serializer_test_files(root_directory)
        when "additional_file_patterns" then additional_file_patterns
        when "controller" then controller_files(root_directory)
        when "controller_test" then controller_test_files(root_directory)
        when "admin" then active_admin_files(root_directory)
        when "helper" then helper_files(root_directory)
        when "request_spec" then request_spec_files(root_directory)
        when "routing_spec" then routing_spec_files(root_directory)
        else
          []
        end
      end

      def controller_files(root_directory)
        [
          File.join(root_directory, FilePatterns::CONTROLLER_DIR, "%PLURALIZED_MODEL_NAME%_controller.rb")
        ]
      end

      def controller_test_files(root_directory)
        [
          File.join(root_directory, FilePatterns::CONTROLLER_TEST_DIR, "%PLURALIZED_MODEL_NAME%_controller_test.rb"),
          File.join(root_directory, FilePatterns::CONTROLLER_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_controller_spec.rb")
        ]
      end

      def additional_file_patterns
        [
          @options[:additional_file_patterns] || []
        ].flatten
      end

      def active_admin_files(root_directory)
        [
          File.join(root_directory, FilePatterns::ACTIVEADMIN_DIR, "%MODEL_NAME%.rb"),
          File.join(root_directory, FilePatterns::ACTIVEADMIN_DIR, "%PLURALIZED_MODEL_NAME%.rb")
        ]
      end

      def helper_files(root_directory)
        [
          File.join(root_directory, FilePatterns::HELPER_DIR, "%PLURALIZED_MODEL_NAME%_helper.rb")
        ]
      end

      def test_files(root_directory)
        [
          File.join(root_directory, FilePatterns::UNIT_TEST_DIR, "%MODEL_NAME%_test.rb"),
          File.join(root_directory, FilePatterns::MODEL_TEST_DIR, "%MODEL_NAME%_test.rb"),
          File.join(root_directory, FilePatterns::SPEC_MODEL_DIR, "%MODEL_NAME%_spec.rb")
        ]
      end

      def fixture_files(root_directory)
        [
          File.join(root_directory, FilePatterns::FIXTURE_TEST_DIR, "%TABLE_NAME%.yml"),
          File.join(root_directory, FilePatterns::FIXTURE_SPEC_DIR, "%TABLE_NAME%.yml"),
          File.join(root_directory, FilePatterns::FIXTURE_TEST_DIR, "%PLURALIZED_MODEL_NAME%.yml"),
          File.join(root_directory, FilePatterns::FIXTURE_SPEC_DIR, "%PLURALIZED_MODEL_NAME%.yml")
        ]
      end

      def scaffold_files(root_directory)
        controller_test_files(root_directory) + request_spec_files(root_directory) + routing_spec_files(root_directory)
      end

      def request_spec_files(root_directory)
        [
          File.join(root_directory, FilePatterns::REQUEST_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_spec.rb")
        ]
      end

      def routing_spec_files(root_directory)
        [
          File.join(root_directory, FilePatterns::ROUTING_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_routing_spec.rb")
        ]
      end

      def factory_files(root_directory)
        [
          File.join(root_directory, FilePatterns::EXEMPLARS_TEST_DIR, "%MODEL_NAME%_exemplar.rb"),
          File.join(root_directory, FilePatterns::EXEMPLARS_SPEC_DIR, "%MODEL_NAME%_exemplar.rb"),
          File.join(root_directory, FilePatterns::BLUEPRINTS_TEST_DIR, "%MODEL_NAME%_blueprint.rb"),
          File.join(root_directory, FilePatterns::BLUEPRINTS_SPEC_DIR, "%MODEL_NAME%_blueprint.rb"),
          File.join(root_directory, FilePatterns::FACTORY_BOT_TEST_DIR, "%MODEL_NAME%_factory.rb"), # (old style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_SPEC_DIR, "%MODEL_NAME%_factory.rb"), # (old style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_TEST_DIR, "%TABLE_NAME%.rb"), # (new style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_SPEC_DIR, "%TABLE_NAME%.rb"), # (new style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_TEST_DIR, "%PLURALIZED_MODEL_NAME%.rb"), # (new style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_SPEC_DIR, "%PLURALIZED_MODEL_NAME%.rb"), # (new style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_TEST_DIR, "%PLURALIZED_MODEL_NAME%_factory.rb"), # (new style)
          File.join(root_directory, FilePatterns::FACTORY_BOT_SPEC_DIR, "%PLURALIZED_MODEL_NAME%_factory.rb"), # (new style)
          File.join(root_directory, FilePatterns::FABRICATORS_TEST_DIR, "%MODEL_NAME%_fabricator.rb"),
          File.join(root_directory, FilePatterns::FABRICATORS_SPEC_DIR, "%MODEL_NAME%_fabricator.rb")
        ]
      end

      def serialize_files(root_directory)
        [
          File.join(root_directory, FilePatterns::SERIALIZERS_DIR, "%MODEL_NAME%_serializer.rb")
        ]
      end

      def serializer_test_files(root_directory)
        [
          File.join(root_directory, FilePatterns::SERIALIZERS_TEST_DIR, "%MODEL_NAME%_serializer_test.rb"),
          File.join(root_directory, FilePatterns::SERIALIZERS_SPEC_DIR, "%MODEL_NAME%_serializer_spec.rb")
        ]
      end
    end
  end
end
