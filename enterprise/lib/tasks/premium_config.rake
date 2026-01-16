namespace :premium do
  desc 'Force load premium installation configs'
  task load_configs: :environment do
    puts "=== Carregando configurações premium ==="
    
    config_path = Rails.root.join('enterprise/config')
    premium_config_file = config_path.join('premium_installation_config.yml').to_s
    
    unless File.exist?(premium_config_file)
      puts "❌ Arquivo não encontrado: #{premium_config_file}"
      next
    end
    
    premium_config = YAML.safe_load(File.read(premium_config_file))
    
    premium_config.each do |config|
      new_config = config.with_indifferent_access
      existing_config = InstallationConfig.find_by(name: new_config[:name])
      
      if existing_config
        if existing_config.value != new_config[:value]
          puts "Atualizando #{new_config[:name]}: '#{existing_config.value}' -> '#{new_config[:value]}'"
          existing_config.update!(value: new_config[:value])
        end
      else
        puts "Criando #{new_config[:name]} = '#{new_config[:value]}'"
        InstallationConfig.create!(
          name: new_config[:name],
          value: new_config[:value],
          locked: true
        )
      end
    end
    
    GlobalConfig.clear_cache
    puts "✅ Configurações carregadas e cache limpo!"
    
    puts "\nConfigurações atuais:"
    %w[INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL BRAND_NAME].each do |key|
      config = InstallationConfig.find_by(name: key)
      puts "  #{key}: #{config ? config.value : 'N/A'}"
    end
  end
end
