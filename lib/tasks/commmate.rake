# frozen_string_literal: true

namespace :commmate do
  desc 'Apply CommMate branding to database'
  task branding: :environment do
    puts '🎨 Applying CommMate branding...'
    
    begin
      # Update branding (idempotent - safe to run multiple times)
      InstallationConfig.find_or_create_by!(name: 'INSTALLATION_NAME').update!(value: 'CommMate')
      InstallationConfig.find_or_create_by!(name: 'BRAND_NAME').update!(value: 'CommMate')
      
      # Update URLs
      InstallationConfig.find_or_create_by!(name: 'BRAND_URL').update!(value: 'https://commmate.com')
      InstallationConfig.find_or_create_by!(name: 'WIDGET_BRAND_URL').update!(value: 'https://commmate.com')
      InstallationConfig.find_or_create_by!(name: 'TERMS_URL').update!(value: 'https://commmate.com/terms')
      InstallationConfig.find_or_create_by!(name: 'PRIVACY_URL').update!(value: 'https://commmate.com/privacy')
      
      # Update logos
      InstallationConfig.find_or_create_by!(name: 'LOGO').update!(value: '/brand-assets/logo-full.png')
      InstallationConfig.find_or_create_by!(name: 'LOGO_DARK').update!(value: '/brand-assets/logo-full-dark.png')
      InstallationConfig.find_or_create_by!(name: 'LOGO_THUMBNAIL').update!(value: '/brand-assets/logo_thumbnail.png')
      
      # Disable SSO/OAuth
      InstallationConfig.where(name: 'IS_ENTERPRISE').delete_all
      
      puts '✅ CommMate branding applied successfully!'
    rescue StandardError => e
      puts "❌ Error applying CommMate branding: #{e.message}"
      raise
    end
  end
  
  desc 'Verify CommMate branding configuration'
  task verify: :environment do
    puts '🔍 Verifying CommMate branding...'
    
    checks = {
      'Installation Name' => InstallationConfig.find_by(name: 'INSTALLATION_NAME')&.value,
      'Brand Name' => InstallationConfig.find_by(name: 'BRAND_NAME')&.value,
      'Brand URL' => InstallationConfig.find_by(name: 'BRAND_URL')&.value,
      'Logo' => InstallationConfig.find_by(name: 'LOGO')&.value,
      'Logo Dark' => InstallationConfig.find_by(name: 'LOGO_DARK')&.value,
      'Logo Thumbnail' => InstallationConfig.find_by(name: 'LOGO_THUMBNAIL')&.value
    }
    
    checks.each do |name, value|
      status = value&.include?('CommMate') || value&.include?('commmate') || value&.include?('brand-assets') ? '✅' : '❌'
      puts "#{status} #{name}: #{value || 'NOT SET'}"
    end
    
    is_enterprise = InstallationConfig.exists?(name: 'IS_ENTERPRISE')
    puts "#{is_enterprise ? '❌' : '✅'} SSO/Enterprise: #{is_enterprise ? 'ENABLED (should be disabled)' : 'Disabled'}"
  end
end
