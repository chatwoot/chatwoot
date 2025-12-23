# frozen_string_literal: true

require 'tmpdir'

RSpec.shared_context 'isolated environment' do # rubocop:disable Metrics/BlockLength
  around do |example|
    Dir.mktmpdir do |tmpdir|
      original_home = Dir.home
      original_xdg_config_home = ENV.fetch('XDG_CONFIG_HOME', nil)

      # Make sure to expand all symlinks in the path first. Otherwise we may
      # get mismatched pathnames when loading config files later on.
      tmpdir = File.realpath(tmpdir)
      # Make upwards search for .rubocop.yml files stop at this directory.
      RuboCop::FileFinder.root_level = tmpdir

      virtual_home = File.expand_path(File.join(tmpdir, 'home'))
      Dir.mkdir(virtual_home)
      ENV['HOME'] = virtual_home
      ENV.delete('XDG_CONFIG_HOME')

      base_dir = example.metadata[:project_inside_home] ? virtual_home : tmpdir
      root = example.metadata[:root]
      working_dir = root ? File.join(base_dir, 'work', root) : File.join(base_dir, 'work')

      begin
        FileUtils.mkdir_p(working_dir)

        Dir.chdir(working_dir) { example.run }
      ensure
        ENV['HOME'] = original_home
        ENV['XDG_CONFIG_HOME'] = original_xdg_config_home

        RuboCop::FileFinder.root_level = nil
      end
    end
  end

  if RuboCop.const_defined?(:Server)
    around do |example|
      RuboCop::Server::Cache.cache_root_path = nil
      RuboCop::Server::Cache.instance_variable_set(:@project_dir_cache_key, nil)
      begin
        example.run
      ensure
        RuboCop::Server::Cache.cache_root_path = nil
        RuboCop::Server::Cache.instance_variable_set(:@project_dir_cache_key, nil)
      end
    end
  end
end

# Workaround for https://github.com/rubocop/rubocop/issues/12978,
# there should already be no gemfile in the temp directory
RSpec.shared_context 'isolated bundler' do
  around do |example|
    # No bundler env and reset cached gemfile path
    Bundler.with_unbundled_env do
      old_values = Bundler.instance_variables.to_h do |name|
        [name, Bundler.instance_variable_get(name)]
      end
      Bundler.instance_variables.each { |name| Bundler.remove_instance_variable(name) }
      example.call
    ensure
      Bundler.instance_variables.each { |name| Bundler.remove_instance_variable(name) }
      old_values.each do |name, value|
        Bundler.instance_variable_set(name, value)
      end
    end
  end
end

RSpec.shared_context 'maintain registry' do
  around(:each) { |example| RuboCop::Cop::Registry.with_temporary_global { example.run } }

  def stub_cop_class(name, inherit: RuboCop::Cop::Base, &block)
    klass = Class.new(inherit, &block)
    stub_const(name, klass)
    klass
  end
end

RSpec.shared_context 'maintain default configuration' do
  around(:each) do |example|
    # Make a copy of the current configuration that will not change when source hash changes
    default_configuration = RuboCop::ConfigLoader.default_configuration
    config = RuboCop::Config.create(
      default_configuration.to_h.clone,
      default_configuration.loaded_path
    )

    example.run

    RuboCop::ConfigLoader.instance_variable_set(:@default_configuration, config)
  end
end

# This context assumes nothing and defines `cop`, among others.
RSpec.shared_context 'config' do # rubocop:disable Metrics/BlockLength
  ### Meant to be overridden at will

  let(:cop_class) do
    unless described_class.is_a?(Class) && described_class < RuboCop::Cop::Base
      raise 'Specify which cop class to use (e.g `let(:cop_class) { RuboCop::Cop::Base }`)'
    end

    described_class
  end

  let(:cop_config) { {} }

  let(:other_cops) { {} }

  let(:cop_options) { {} }

  let(:gem_versions) { {} }

  ### Utilities

  def source_range(range, buffer: source_buffer)
    Parser::Source::Range.new(buffer, range.begin,
                              range.exclude_end? ? range.end : range.end + 1)
  end

  ### Useful intermediary steps (less likely to be overridden)

  let(:processed_source) { parse_source(source, 'test') }

  let(:source_buffer) { processed_source.buffer }

  let(:all_cops_config) do
    rails = { 'TargetRubyVersion' => ruby_version }
    rails['TargetRailsVersion'] = rails_version if rails_version
    rails
  end

  let(:cur_cop_config) do
    RuboCop::ConfigLoader
      .default_configuration.for_cop(cop_class)
      .merge(
        'Enabled' => true, # in case it is 'pending'
        'AutoCorrect' => 'always' # in case defaults set it to 'disabled' or false
      )
      .merge(cop_config)
  end

  let(:config) do
    hash = { 'AllCops' => all_cops_config, cop_class.cop_name => cur_cop_config }.merge!(other_cops)

    config = RuboCop::Config.new(hash, "#{Dir.pwd}/.rubocop.yml")

    rails_version_in_gemfile = Gem::Version.new(
      rails_version || RuboCop::Config::DEFAULT_RAILS_VERSION
    )

    allow(config).to receive(:gem_versions_in_target).and_return(
      {
        'railties' => rails_version_in_gemfile,
        **gem_versions.transform_values { |value| Gem::Version.new(value) }
      }
    )

    config
  end

  let(:cop) { cop_class.new(config, cop_options) }
end

RSpec.shared_context 'mock console output' do
  before do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after do
    $stdout = STDOUT
    $stderr = STDERR
  end
end

RSpec.shared_context 'mock obsoletion' do
  include_context 'mock console output'

  let(:obsoletion_configuration_path) { 'obsoletions.yml' }

  before do
    RuboCop::ConfigObsoletion.reset!
    allow(RuboCop::ConfigObsoletion).to receive(:files).and_return([obsoletion_configuration_path])
  end

  after do
    RuboCop::ConfigObsoletion.reset!
  end
end

RSpec.shared_context 'lsp' do
  before do
    RuboCop::LSP.enable
  end

  after do
    RuboCop::LSP.disable
  end
end

RSpec.shared_context 'ruby 2.0' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.0 }
end

RSpec.shared_context 'ruby 2.1' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.1 }
end

RSpec.shared_context 'ruby 2.2' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.2 }
end

RSpec.shared_context 'ruby 2.3' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.3 }
end

RSpec.shared_context 'ruby 2.4' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.4 }
end

RSpec.shared_context 'ruby 2.5' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.5 }
end

RSpec.shared_context 'ruby 2.6' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.6 }
end

RSpec.shared_context 'ruby 2.7' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 2.7 }
end

RSpec.shared_context 'ruby 3.0' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.0 }
end

RSpec.shared_context 'ruby 3.1' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.1 }
end

RSpec.shared_context 'ruby 3.2' do
  # Prism supports parsing Ruby 3.3+.
  let(:ruby_version) { ENV['PARSER_ENGINE'] == 'parser_prism' ? 3.3 : 3.2 }
end

RSpec.shared_context 'ruby 3.3' do
  let(:ruby_version) { 3.3 }
end

RSpec.shared_context 'ruby 3.4' do
  let(:ruby_version) { 3.4 }
end

RSpec.shared_context 'ruby 3.5' do
  let(:ruby_version) { 3.5 }
end
