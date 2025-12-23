# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative '../../new_relic/language_support'
require 'thor'

class Instrumentation < Thor
  include Thor::Actions

  INSTRUMENTATION_ROOT = 'lib/new_relic/agent/instrumentation/'
  MULTIVERSE_SUITE_ROOT = 'test/multiverse/suites/'
  DEFAULT_SOURCE_LOCATION = 'lib/new_relic/agent/configuration/default_source.rb'
  NEWRELIC_YML_LOCATION = 'newrelic.yml'

  desc('scaffold NAME', 'Scaffold the required files for adding new instrumentation')
  long_desc <<~LONGDESC
    `instrumentation scaffold` requires one parameter by default: the name of the
    library or class you are instrumenting. This task generates the basic
    file structure needed to add new instrumentation to the Ruby agent.
  LONGDESC

  source_root(File.dirname(__FILE__))

  option :method,
    default: 'method_to_instrument',
    desc: 'The method you would like to prepend or chain instrumentation onto'
  option :args,
    default: '*args',
    desc: 'The arguments associated with the original method'

  def scaffold(name)
    @name = name
    @method = options[:method] if options[:method]
    @args = options[:args] if options[:args]
    @class_name = ::NewRelic::LanguageSupport.camelize(name)
    base_path = "#{INSTRUMENTATION_ROOT}#{name.downcase}"

    empty_directory(base_path)
    create_instrumentation_files(base_path)
    append_to_default_source(name)
    append_to_newrelic_yml(name)
    create_tests(name)
  end

  desc 'add_new_method NAME', 'Inserts a new method into an existing piece of instrumentation'

  option :method, required: true, desc: 'The name of the method to instrument'
  option :args, default: '*args', desc: 'The arguments associated with the instrumented method'

  def add_new_method(name, method_name)
    # Verify that existing instrumentation exists
    # if it doesn't, should we just call the #scaffold method instead since we have all the stuff
    # otherwise, inject the new method into the instrumentation matching the first arg
    # add to only chain, instrumentation, prepend
    # move the method content to a partial
  end

  private

  def create_instrumentation_files(base_path)
    %w[chain instrumentation prepend].each do |file|
      template("templates/#{file}.tt", "#{base_path}/#{file}.rb")
    end

    template('templates/dependency_detection.tt', "#{base_path}.rb")
  end

  def create_tests(name)
    @name = name
    @instrumentation_method_global_erb_snippet = '<%= $instrumentation_method %>'
    base_path = "#{MULTIVERSE_SUITE_ROOT}#{@name.downcase}"
    empty_directory(base_path)
    template('templates/Envfile.tt', "#{base_path}/Envfile")
    template('templates/test.tt', "#{base_path}/#{@name.downcase}_instrumentation_test.rb")

    empty_directory("#{base_path}/config")
    template('templates/newrelic.yml.tt', "#{base_path}/config/newrelic.yml")
  end

  def append_to_default_source(name)
    insert_into_file(
      DEFAULT_SOURCE_LOCATION,
      config_block(name.downcase),
      after: ":description => 'Controls auto-instrumentation of bunny at start-up.  May be one of [auto|prepend|chain|disabled].'
        },\n"
    )
  end

  def append_to_newrelic_yml(name)
    insert_into_file(
      NEWRELIC_YML_LOCATION,
      yaml_block(name),
      after: "# instrumentation.bunny: auto\n"
    )
  end

  def config_block(name)
    <<~CONFIG
      :'instrumentation.#{name.downcase}' => {
        :default => 'auto',
        :public => true,
        :type => String,
        :dynamic_name => true,
        :allowed_from_server => false,
        :description => 'Controls auto-instrumentation of the #{name} library at start-up. May be one of [auto|prepend|chain|disabled].'
      },
    CONFIG
  end

  def yaml_block(name)
    <<~HEREDOC

      # Controls auto-instrumentation of #{name} at start-up.
      # May be one of [auto|prepend|chain|disabled]
      # instrumentation.#{name.downcase}: auto
    HEREDOC
  end
end

Instrumentation.start(ARGV)
