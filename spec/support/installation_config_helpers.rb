module InstallationConfigHelpers
  def set_installation_config(name, value)
    config = InstallationConfig.find_or_initialize_by(name: name)
    config.locked = false if config.new_record?
    config.value = value
    config.save!
  end
end

RSpec.configure do |config|
  config.include InstallationConfigHelpers
end
