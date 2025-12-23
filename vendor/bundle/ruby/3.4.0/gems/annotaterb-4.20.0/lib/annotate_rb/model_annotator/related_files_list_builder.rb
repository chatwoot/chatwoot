# frozen_string_literal: true

module AnnotateRb
  module ModelAnnotator
    # Given a model file and options, this class will return a list of related files (e.g. fixture, controllers, etc)
    # to also annotate
    class RelatedFilesListBuilder
      RELATED_TYPES = %w[test fixture factory serializer scaffold controller helper].freeze

      # Valid options when `:exclude_tests` is an Array, note that symbols are expected
      EXCLUDE_TEST_OPTIONS = %i[model controller serializer request routing].freeze

      def initialize(file, model_name, table_name, options)
        @file = file
        @model_name = model_name
        @table_name = table_name
        @options = options
      end

      def build
        @list = []

        add_related_test_files if !exclude_model_test_files?
        add_related_fixture_files if !@options[:exclude_fixtures]
        add_related_factory_files if !@options[:exclude_factories]
        add_related_serializer_files if !@options[:exclude_serializers]
        add_related_serializer_test_files if !exclude_serializer_tests?
        add_related_controller_test_files if !exclude_controller_tests?
        add_related_request_spec_files if !exclude_request_specs?
        add_related_routing_spec_files if !exclude_routing_specs?
        add_related_controller_files if !@options[:exclude_controllers]
        add_related_helper_files if !@options[:exclude_helpers]
        add_related_admin_files if @options[:active_admin]
        add_additional_file_patterns if @options[:additional_file_patterns].present?

        @list.uniq
      end

      private

      def exclude_model_test_files?
        option = @options[:exclude_tests]

        # If exclude_tests: [:model] then
        # 1) we want to exclude model test files, and
        # 2) we don't want to include model test files
        if option.is_a?(Array)
          option.include?(:model)
        else
          option
        end
      end

      def exclude_serializer_tests?
        if @options[:exclude_tests].is_a?(Array)
          @options[:exclude_tests].include?(:serializer)
        else
          @options[:exclude_serializers]
        end
      end

      def exclude_controller_tests?
        if @options[:exclude_tests].is_a?(Array)
          @options[:exclude_tests].include?(:controller)
        else
          @options[:exclude_scaffolds]
        end
      end

      def exclude_routing_specs?
        if @options[:exclude_tests].is_a?(Array)
          @options[:exclude_tests].include?(:routing)
        else
          @options[:exclude_scaffolds]
        end
      end

      def exclude_request_specs?
        if @options[:exclude_tests].is_a?(Array)
          @options[:exclude_tests].include?(:request)
        else
          @options[:exclude_scaffolds]
        end
      end

      def related_files_for_pattern(pattern_type)
        patterns = PatternGetter.call(@options, pattern_type)

        patterns
          .map { |f| FileNameResolver.call(f, @model_name, @table_name) }
          .map { |f| Dir.glob(f) }
          .flatten
      end

      def add_related_test_files
        position_key = :position_in_test
        pattern_type = "test"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_fixture_files
        position_key = :position_in_fixture
        pattern_type = "fixture"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_factory_files
        position_key = :position_in_factory
        pattern_type = "factory"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_serializer_files
        position_key = :position_in_serializer
        pattern_type = "serializer"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_serializer_test_files
        position_key = :position_in_serializer
        pattern_type = "serializer_test"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_controller_files
        position_key = :position_in_controller # Key does not exist
        pattern_type = "controller"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_controller_test_files
        position_key = :position_in_scaffold # Key does not exist
        pattern_type = "controller_test"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_request_spec_files
        position_key = :position_in_scaffold # Key does not exist
        pattern_type = "request_spec"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_routing_spec_files
        position_key = :position_in_scaffold # Key does not exist
        pattern_type = "routing_spec"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_helper_files
        position_key = :position_in_helper # Key does not exist
        pattern_type = "helper"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_related_admin_files
        position_key = :position_in_admin # Key does not exist
        pattern_type = "admin"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end

      def add_additional_file_patterns
        position_key = :position_in_additional_file_patterns
        pattern_type = "additional_file_patterns"

        related_files = related_files_for_pattern(pattern_type)
        files_with_position_key = related_files.map { |f| [f, position_key] }

        @list.concat(files_with_position_key)
      end
    end
  end
end
