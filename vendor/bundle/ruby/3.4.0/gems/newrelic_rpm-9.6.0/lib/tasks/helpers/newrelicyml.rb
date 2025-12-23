# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require_relative '../../new_relic/agent/configuration/default_source'

module NewRelicYML
  CRITICAL = [:'agent_enabled', :'app_name', :'license_key', :'log_level']
  DEFAULTS = NewRelic::Agent::Configuration::DEFAULTS
  # Skip because not configurable via yml
  SKIP = [:'defer_rails_initialization']
  # Don't evaluate Procs, instead use set values
  PROCS = {:'config_path' => 'newrelic.yml',
           :'process_host.display_name' => 'default hostname',
           :'transaction_tracer.transaction_threshold' => 1.0}

  HEADER = <<~HEADER
    #
    # This file configures the New Relic Agent.  New Relic monitors Ruby, Java,
    # .NET, PHP, Python, Node, and Go applications with deep visibility and low
    # overhead.  For more information, visit www.newrelic.com.

    # Generated <%= Time.now.strftime('%B %d, %Y') %><%= ", for version \#{@agent_version}" if @agent_version %>
    #<%= "\\n# \#{generated_for_user}\\n#" if generated_for_user %>
    # For full documentation of agent configuration options, please refer to
    # https://docs.newrelic.com/docs/agents/ruby-agent/installation-configuration/ruby-agent-configuration

    common: &default_settings
      # Required license key associated with your New Relic account.
      license_key: <%= license_key %>

      # Your application name. Renaming here affects where data displays in New
      # Relic. For more details, see https://docs.newrelic.com/docs/apm/new-relic-apm/maintenance/renaming-applications
      app_name: <%= app_name %>

      # To disable the agent regardless of other settings, uncomment the following:
      # agent_enabled: false

      # Logging level for log/newrelic_agent.log; options are error, warn, info, or
      # debug.
      log_level: info

      # All of the following configuration options are optional. Review them, and
      # uncomment or edit them if they appear relevant to your application needs.

  HEADER

  FOOTER = <<~FOOTER
    # Environment-specific settings are in this section.
    # RAILS_ENV or RACK_ENV (as appropriate) is used to determine the environment.
    # If your application has other named environments, configure them here.
    development:
      <<: *default_settings
      app_name: <%= app_name %> (Development)

    test:
      <<: *default_settings
      # It doesn't make sense to report to New Relic from automated test runs.
      monitor_mode: false

    staging:
      <<: *default_settings
      app_name: <%= app_name %> (Staging)

    production:
      <<: *default_settings
  FOOTER

  def self.get_configs(defaults)
    defaults.sort.each_with_object({}) do |(key, value), final_configs|
      next if CRITICAL.include?(key) || SKIP.include?(key)

      next unless public_config?(value) && !deprecated?(value)

      sanitized_description = sanitize_description(value[:description])
      description = format_description(sanitized_description)
      default = default_value(key, value)
      final_configs[key] = {description: description, default: default}
    end
  end

  def self.public_config?(value)
    value[:public] == true
  end

  def self.deprecated?(value)
    value[:deprecated] == true
  end

  def self.sanitize_description(description)
    # remove callouts
    description = description.split("\n").reject { |line| line.match?('</?Callout') }.join("\n")
    # remove InlinePopover, keep the text inside type
    description.gsub!(/<InlinePopover type="(.*)" \/>/, '\1')
    # remove hyperlinks
    description.gsub!(/\[([^\]]+)\]\([^\)]+\)/, '\1')
    # remove single pairs of backticks
    description.gsub!(/`([^`]+)`/, '\1')
    # removed href links
    description.gsub!(/<a href="(.*)">(.*)<\/a>/, '\2')

    description
  end

  def self.format_description(description)
    # remove leading and trailing whitespace
    description.strip!
    # wrap text after 80 characters
    description.gsub!(/(.{1,80})(\s+|\Z)/, "\\1\n")
    # add hashtags to lines
    description = description.split("\n").map { |line| "  # #{line}" }.join("\n")

    description
  end

  def self.default_value(key, config_hash)
    if PROCS.include?(key)
      PROCS[key]
    else
      default = config_hash[:documentation_default].nil? ? config_hash[:default] : config_hash[:documentation_default]
      default = 'nil' if default.nil?
      default = '""' if default == ''

      default
    end
  end

  def self.build_string(defaults)
    configs = get_configs(defaults)
    yml_string = ''

    configs.each do |key, value|
      yml_string += "#{value[:description]}\n  # #{key}: #{value[:default]}\n\n"
    end

    yml_string
  end

  # :nocov:
  def self.write_file(defaults = DEFAULTS)
    File.write('newrelic.yml', HEADER + build_string(defaults) + FOOTER)
  end
  # :nocov:
end
