namespace :buzz do
  desc 'Setup Buzz branding configuration'
  task setup_branding: :environment do
    puts 'Setting up Buzz branding...'
    
    # Load configuration from YAML file
    ConfigLoader.new.process
    puts 'Loaded configuration from installation_config.yml'
    
    # Ensure INSTALLATION_NAME is set to 'Buzz'
    installation_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_NAME')
    installation_config.update(value: 'Buzz')
    puts "Set INSTALLATION_NAME to: #{installation_config.value}"
    
    # Verify other branding configs
    brand_name = InstallationConfig.find_by(name: 'BRAND_NAME')
    if brand_name&.value == 'Chatwoot'
      brand_name.update(value: 'Buzz')
      puts "Updated BRAND_NAME from 'Chatwoot' to 'Buzz'"
    end
    
    puts 'Buzz branding setup complete!'
  end
  
  desc 'Verify Buzz branding configuration'
  task verify_branding: :environment do
    puts 'Verifying Buzz branding configuration...'
    
    installation_name = GlobalConfig.get('INSTALLATION_NAME')
    brand_name = GlobalConfig.get('BRAND_NAME')
    
    puts "INSTALLATION_NAME: #{installation_name}"
    puts "BRAND_NAME: #{brand_name}"
    
    if installation_name['INSTALLATION_NAME'] == 'Buzz'
      puts '✅ INSTALLATION_NAME is correctly set to Buzz'
    else
      puts '❌ INSTALLATION_NAME is not set to Buzz'
    end
  end
end
