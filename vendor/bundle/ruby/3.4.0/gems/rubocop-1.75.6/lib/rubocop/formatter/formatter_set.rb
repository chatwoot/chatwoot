# frozen_string_literal: true

require 'fileutils'

module RuboCop
  module Formatter
    # This is a collection of formatters. A FormatterSet can hold multiple
    # formatter instances and provides transparent formatter API methods
    # which invoke same method of each formatters.
    class FormatterSet < Array
      BUILTIN_FORMATTERS_FOR_KEYS = {
        '[a]utogenconf' => 'AutoGenConfigFormatter',
        '[c]lang'       => 'ClangStyleFormatter',
        '[e]macs'       => 'EmacsStyleFormatter',
        '[fi]les'       => 'FileListFormatter',
        '[fu]ubar'      => 'FuubarStyleFormatter',
        '[g]ithub'      => 'GitHubActionsFormatter',
        '[h]tml'        => 'HTMLFormatter',
        '[j]son'        => 'JSONFormatter',
        '[ju]nit'       => 'JUnitFormatter',
        '[m]arkdown'    => 'MarkdownFormatter',
        '[o]ffenses'    => 'OffenseCountFormatter',
        '[pa]cman'      => 'PacmanFormatter',
        '[p]rogress'    => 'ProgressFormatter',
        '[q]uiet'       => 'QuietFormatter',
        '[s]imple'      => 'SimpleTextFormatter',
        '[t]ap'         => 'TapFormatter',
        '[w]orst'       => 'WorstOffendersFormatter'
      }.freeze
      BUILTIN_FORMATTER_NAMES = BUILTIN_FORMATTERS_FOR_KEYS.keys.map { |key| key.delete('[]') }

      FORMATTER_APIS = %i[started finished].freeze

      FORMATTER_APIS.each do |method_name|
        define_method(method_name) do |*args|
          each { |f| f.public_send(method_name, *args) }
        end
      end

      def initialize(options = {})
        super()
        @options = options # CLI options
      end

      def file_started(file, options)
        @options = options[:cli_options]
        @config_store = options[:config_store]
        each { |f| f.file_started(file, options) }
      end

      def file_finished(file, offenses)
        each { |f| f.file_finished(file, offenses) }
        offenses
      end

      def add_formatter(formatter_type, output_path = nil)
        if output_path
          dir_path = File.dirname(output_path)
          FileUtils.mkdir_p(dir_path)
          output = File.open(output_path, 'w')
        else
          output = $stdout
        end

        self << formatter_class(formatter_type).new(output, @options)
      end

      def close_output_files
        each do |formatter|
          formatter.output.close if formatter.output.is_a?(File)
        end
      end

      private

      def formatter_class(formatter_type)
        case formatter_type
        when Class
          formatter_type
        when /\A(::)?[A-Z]/
          custom_formatter_class(formatter_type)
        else
          builtin_formatter_class(formatter_type)
        end
      end

      def builtin_formatter_class(specified_key)
        matching_keys = BUILTIN_FORMATTERS_FOR_KEYS.keys.select do |key|
          /^\[#{specified_key}\]/.match?(key) || specified_key == key.delete('[]')
        end

        if matching_keys.empty?
          similar_name = NameSimilarity.find_similar_name(specified_key, BUILTIN_FORMATTER_NAMES)
          suggestion = %( Did you mean? "#{similar_name}") if similar_name

          raise Rainbow(%(Formatter "#{specified_key}" not found.#{suggestion})).red
        end

        raise %(Cannot determine formatter for "#{specified_key}") if matching_keys.size > 1

        formatter_name = BUILTIN_FORMATTERS_FOR_KEYS[matching_keys.first]
        RuboCop::Formatter.const_get(formatter_name)
      end

      def custom_formatter_class(specified_class_name)
        constant_names = specified_class_name.split('::')
        constant_names.shift if constant_names.first.empty?
        constant_names.reduce(Object) do |namespace, constant_name|
          namespace.const_get(constant_name, false)
        end
      end
    end
  end
end
