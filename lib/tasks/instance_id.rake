namespace :instance_id do
  desc 'Get the installation identifier'
  task :get_installation_identifier => :environment do
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    puts identifier
  end
end
