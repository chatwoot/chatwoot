# frozen_string_literal: true

module RuboCop
  # This module holds the RuboCop version information.
  module Version
    STRING = '1.75.6'

    MSG = '%<version>s (using %<parser_version>s, ' \
          'rubocop-ast %<rubocop_ast_version>s, ' \
          'analyzing as Ruby %<target_ruby_version>s, ' \
          'running on %<ruby_engine>s %<ruby_version>s)%<server_mode>s [%<ruby_platform>s]'

    MINIMUM_PARSABLE_PRISM_VERSION = 3.3

    CANONICAL_FEATURE_NAMES = {
      'Rspec' => 'RSpec', 'Graphql' => 'GraphQL', 'Md' => 'Markdown', 'Factory_bot' => 'FactoryBot',
      'Thread_safety' => 'ThreadSafety', 'Rspec_rails' => 'RSpecRails'
    }.freeze
    EXTENSION_PATH_NAMES = {
      'rubocop-md' => 'markdown', 'rubocop-factory_bot' => 'factory_bot'
    }.freeze

    # NOTE: Marked as private but used by gems like standard.
    # @api private
    # rubocop:disable Metrics/MethodLength
    def self.version(debug: false, env: nil)
      if debug
        target_ruby_version = target_ruby_version(env)
        verbose_version = format(MSG, version: STRING,
                                      parser_version: parser_version(target_ruby_version),
                                      rubocop_ast_version: RuboCop::AST::Version::STRING,
                                      target_ruby_version: target_ruby_version,
                                      ruby_engine: RUBY_ENGINE, ruby_version: RUBY_VERSION,
                                      server_mode: server_mode,
                                      ruby_platform: RUBY_PLATFORM)
        return verbose_version unless env

        extension_versions = extension_versions(env)
        return verbose_version if extension_versions.empty?

        <<~VERSIONS
          #{verbose_version}
          #{extension_versions.join("\n")}
        VERSIONS
      else
        STRING
      end
    end
    # rubocop:enable Metrics/MethodLength

    # @api private
    def self.verbose(env: nil)
      version(debug: true, env: env)
    end

    # @api private
    def self.parser_version(target_ruby_version)
      config_path = ConfigFinder.find_config_path(Dir.pwd)
      yaml = Util.silence_warnings do
        ConfigLoader.load_yaml_configuration(config_path)
      end
      parser_engine = yaml.dig('AllCops', 'ParserEngine')
      parser_engine_text = ", #{parser_engine}" if parser_engine

      if target_ruby_version >= MINIMUM_PARSABLE_PRISM_VERSION
        "Parser #{Parser::VERSION}, Prism #{Prism::VERSION}#{parser_engine_text}"
      else
        "Parser #{Parser::VERSION}"
      end
    end

    # @api private
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def self.extension_versions(env)
      plugins = config_for_pwd(env).loaded_plugins
      plugin_versions = plugins.filter_map do |plugin|
        next if Plugin::BUILTIN_INTERNAL_PLUGINS.key?(plugin.about.name)
        next unless (plugin_name = plugin.about.name)

        "  - #{plugin_name} #{plugin.about.version}"
      end

      # TODO: It needs to be maintained for a while to ensure compatibility with extensions that
      # don't support plugins. It should be removed in future once the old style becomes obsolete.
      features = config_for_pwd(env).loaded_features.sort
      features -= plugins.map { |plugin| plugin.about.name }
      feature_versions = features.filter_map do |loaded_feature|
        next unless (match = loaded_feature.match(/rubocop-(?<feature>.*)/))

        # Get the expected name of the folder containing the extension code.
        # Usually it would be the same as the extension name. but sometimes authors
        # can choose slightly different name for their gems, e.g. rubocop-md instead of
        # rubocop-markdown.
        feature = EXTENSION_PATH_NAMES.fetch(loaded_feature, match[:feature])

        begin
          require "rubocop/#{feature}/version"
        rescue LoadError
          # Not worth mentioning libs that are not installed
        end

        next unless (feature_version = feature_version(feature))

        "  - #{loaded_feature} #{feature_version}"
      end

      plugin_versions + feature_versions
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    # @api private
    def self.target_ruby_version(env)
      if env
        config_for_pwd(env).target_ruby_version
      else
        TargetRuby.new(Config.new).version
      end
    end

    # @api private
    def self.config_for_pwd(env)
      Util.silence_warnings do
        # Suppress any config issues when loading the config (ie. deprecations,
        # pending cops, etc.).
        env.config_store.unvalidated.for_pwd
      end
    end

    # Returns feature version in one of two ways:
    #
    # * Find by RuboCop core version style (e.g. rubocop-performance, rubocop-rspec)
    # * Find by `bundle gem` version style (e.g. rubocop-rake)
    #
    # @api private
    def self.feature_version(feature)
      capitalized_feature = feature.capitalize
      extension_name = CANONICAL_FEATURE_NAMES.fetch(capitalized_feature, capitalized_feature)

      # Find by RuboCop core version style (e.g. rubocop-performance, rubocop-rspec)
      RuboCop.const_get(extension_name)::Version::STRING
    rescue NameError
      begin
        # Find by `bundle gem` version style (e.g. rubocop-rake, rubocop-packaging)
        RuboCop.const_get(extension_name)::VERSION
      rescue NameError
        # noop
      end
    end

    # @api private
    def self.document_version
      STRING.match('\d+\.\d+').to_s
    end

    # @api private
    def self.server_mode
      RuboCop.const_defined?(:Server) && Server.running? ? ' +server' : ''
    end
  end
end
