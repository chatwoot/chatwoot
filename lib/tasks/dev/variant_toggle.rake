# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :chatwoot do
  namespace :dev do
    desc 'Toggle between Chatwoot variants with interactive menu'
    task toggle_variant: :environment do
      # Only allow in development environment
      return unless Rails.env.development?

      show_current_variant
      show_variant_menu
      handle_user_selection
    end

    desc 'Show current Chatwoot variant status'
    task show_variant: :environment do
      return unless Rails.env.development?

      show_current_variant
    end

    private

    def show_current_variant
      puts "\n#{('=' * 50)}"
      puts '🚀 CHATWOOT VARIANT MANAGER'
      puts '=' * 50

      # Check InstallationConfig
      deployment_env = InstallationConfig.find_by(name: 'DEPLOYMENT_ENV')&.value
      pricing_plan = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value

      # Determine current variant based on configs
      current_variant = if deployment_env == 'cloud'
                          'Cloud'
                        elsif pricing_plan == 'enterprise'
                          'Enterprise'
                        else
                          'Community'
                        end

      puts "📊 Current Variant: #{current_variant}"
      puts "   Deployment Environment: #{deployment_env || 'Not set'}"
      puts "   Pricing Plan: #{pricing_plan || 'community'}"
      puts ''
    end

    def show_variant_menu
      puts '🎯 Select a variant to switch to:'
      puts ''
      puts '1. 🆓 Community   (Free version with basic features)'
      puts '2. 🏢 Enterprise  (Self-hosted with premium features)'
      puts '3. 🌥️  Cloud       (Cloud deployment with premium features)'
      puts ''
      puts '0. ❌ Cancel'
      puts ''
      print 'Enter your choice (0-3): '
    end

    def handle_user_selection
      choice = $stdin.gets.chomp

      case choice
      when '1'
        switch_to_variant('Community') { configure_community_variant }
      when '2'
        switch_to_variant('Enterprise') { configure_enterprise_variant }
      when '3'
        switch_to_variant('Cloud') { configure_cloud_variant }
      when '0'
        cancel_operation
      else
        invalid_choice
      end

      puts "\n🎉 Changes applied successfully! No restart required."
    end

    def switch_to_variant(variant_name)
      puts "\n🔄 Switching to #{variant_name} variant..."
      yield
      clear_cache
      puts "✅ Successfully switched to #{variant_name} variant!"
    end

    def cancel_operation
      puts "\n❌ Cancelled. No changes made."
      exit 0
    end

    def invalid_choice
      puts "\n❌ Invalid choice. Please select 0-3."
      puts 'No changes made.'
      exit 1
    end

    def configure_community_variant
      update_installation_config('DEPLOYMENT_ENV', 'self-hosted')
      update_installation_config('INSTALLATION_PRICING_PLAN', 'community')
    end

    def configure_enterprise_variant
      update_installation_config('DEPLOYMENT_ENV', 'self-hosted')
      update_installation_config('INSTALLATION_PRICING_PLAN', 'enterprise')
    end

    def configure_cloud_variant
      update_installation_config('DEPLOYMENT_ENV', 'cloud')
      update_installation_config('INSTALLATION_PRICING_PLAN', 'enterprise')
    end

    def update_installation_config(name, value)
      config = InstallationConfig.find_or_initialize_by(name: name)
      config.value = value
      config.save!
      puts "   💾 Updated #{name} → #{value}"
    end

    def clear_cache
      GlobalConfig.clear_cache
      puts '   🗑️  Cleared configuration cache'
    end
  end
end
# rubocop:enable Metrics/BlockLength
