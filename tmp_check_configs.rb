%w[INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL BRAND_NAME].each do |k|
  cfg = InstallationConfig.find_by(name: k)
  puts "#{k}: #{cfg&.value || 'N/A'}"
end
