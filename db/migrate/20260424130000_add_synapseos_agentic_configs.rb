# frozen_string_literal: true

class AddSynapseosAgenticConfigs < ActiveRecord::Migration[7.1]
  CONFIG_NAMES = %w[
    SYNAPSEOS_AGENTIC_URL
    SYNAPSEOS_AGENTIC_USER
    SYNAPSEOS_AGENTIC_PASSWORD
    SYNAPSEOS_AGENTIC_ENABLED
  ].freeze

  CONFIG_DEFAULTS = {
    'SYNAPSEOS_AGENTIC_URL' => nil,
    'SYNAPSEOS_AGENTIC_USER' => 'admin',
    'SYNAPSEOS_AGENTIC_PASSWORD' => nil,
    'SYNAPSEOS_AGENTIC_ENABLED' => 'false'
  }.freeze

  def up
    CONFIG_NAMES.each do |name|
      config = InstallationConfig.find_or_create_by!(name: name) do |c|
        c.value = CONFIG_DEFAULTS[name]
        c.locked = false
      end
      config.update!(locked: false) if config.locked
    end

    GlobalConfig.clear_cache
  end

  def down
    InstallationConfig.where(name: CONFIG_NAMES).destroy_all
    GlobalConfig.clear_cache
  end
end
