# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

module Format
  DEFAULT_CONFIG_PATH = 'ruby-agent-configuration.mdx'

  def output(format)
    result = build_erb(format).result(binding).split("\n").map(&:rstrip).join("\n").gsub('.  ', '. ')
    File.write(DEFAULT_CONFIG_PATH, result)
  end

  private

  def sections
    @sections ||= flatten_config_hash(build_config_hash)
  end

  def add_data_to_sections(sections)
    sections.each do |section|
      section_key = section[0]
      section.insert(1, format_name(section_key))
      section.insert(2, SECTION_DESCRIPTIONS[section_key])
    end
  end

  def build_config_hash
    sections = Hash.new { |hash, key| hash[key] = [] }
    NewRelic::Agent::Configuration::DEFAULTS.each do |key, value|
      next unless value[:public]

      key = key.to_s
      section_key = section_key(key, key.split('.'))
      sections[section_key] << format_sections(key, value)
    end
    sections
  end

  def build_erb(format)
    require 'erb'
    path = File.join(File.dirname(__FILE__), "config.#{format}.erb")
    template = File.read(File.expand_path(path))
    ERB.new(template)
  end

  def flatten_config_hash(config_hash)
    sections = []
    config = [GENERAL, 'transaction_tracer', 'error_collector',
      'browser_monitoring', 'transaction_events',
      'application_logging']

    config.each { |config| sections << pluck(config, config_hash) }

    sections.concat(config_hash.to_a.sort_by { |a| a.first })
    add_data_to_sections(sections)

    sections
  end

  def format_default_value(spec)
    return spec[:documentation_default] if !spec[:documentation_default].nil?

    if spec[:default].is_a?(Proc)
      '(Dynamic)'
    else
      "#{spec[:default].inspect}"
    end
  end

  def format_description(value)
    description = ''
    description += '**DEPRECATED** ' if value[:deprecated]
    description += value[:description]
    description
  end

  def format_env_var(key)
    return 'None' if NON_ENV_CONFIGS.include?(key)

    "NEW_RELIC_#{key.tr('.', '_').upcase}"
  end

  def format_name(key)
    name = NAME_OVERRIDES[key]
    return name if name

    title = key.split('_')
      .each { |fragment| fragment[0] = fragment[0].upcase }
      .join(' ')
    "#{title} [##{key.tr('_', '-')}]"
  end

  def format_sections(key, value)
    {
      :key => key,
      :type => format_type(value[:type]),
      :description => format_description(value),
      :default => format_default_value(value),
      :env_var => format_env_var(key)
    }
  end

  def format_type(type)
    if type == NewRelic::Agent::Configuration::Boolean
      'Boolean'
    else
      type
    end
  end

  def pluck(key, config_hash)
    value = config_hash.delete(key)
    [key, value]
  end

  def section_key(key, components)
    if /^disable_/.match?(key) # "disable_httpclient"
      DISABLING
    elsif components.length >= 2 && !(components[1] == 'attributes') # "analytics_events.enabled"
      components.first
    elsif components[1] == 'attributes' # "transaction_tracer.attributes.enabled"
      ATTRIBUTES
    else
      GENERAL
    end
  end
end
