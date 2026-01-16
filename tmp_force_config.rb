puts "=== Forçando carregamento das configurações premium ==="

# Verifica se o arquivo existe
config_path = Rails.root.join('enterprise/config')
premium_config_file = config_path.join('premium_installation_config.yml').to_s

puts "Procurando arquivo: #{premium_config_file}"
puts "Arquivo existe? #{File.exist?(premium_config_file)}"

if File.exist?(premium_config_file)
  premium_config = YAML.safe_load(File.read(premium_config_file))
  puts "Configurações encontradas: #{premium_config.length}"
  
  premium_config.each do |config|
    new_config = config.with_indifferent_access
    puts "Processando: #{new_config[:name]} = #{new_config[:value]}"
    
    existing_config = InstallationConfig.find_by(name: new_config[:name])
    
    if existing_config
      if existing_config.value != new_config[:value]
        puts "  -> Atualizando de '#{existing_config.value}' para '#{new_config[:value]}'"
        existing_config.update!(value: new_config[:value])
      else
        puts "  -> Já está atualizada"
      end
    else
      puts "  -> Criando nova configuração"
      InstallationConfig.create!(
        name: new_config[:name],
        value: new_config[:value],
        locked: true
      )
    end
  end
  
  GlobalConfig.clear_cache
  puts "\n✅ Cache limpo!"
  
  puts "\n=== Configurações atuais no banco ==="
  %w[INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL BRAND_NAME].each do |key|
    config = InstallationConfig.find_by(name: key)
    puts "#{key}: #{config ? config.value : 'NÃO EXISTE'}"
  end
else
  puts "❌ Arquivo não encontrado: #{premium_config_file}"
end
