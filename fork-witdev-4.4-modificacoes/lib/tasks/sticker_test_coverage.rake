# frozen_string_literal: true

namespace :stickers do
  desc 'Run comprehensive test coverage analysis for sticker feature'
  task test_coverage: :environment do
    puts "🧪 Running WhatsApp Sticker Feature Test Coverage Analysis"
    puts "=" * 60

    # Define all sticker-related files that should have tests
    sticker_files = {
      'Services' => [
        'app/services/sticker_service.rb',
        'app/services/giphy_service.rb',
        'app/services/whatsapp/send_sticker_service.rb',
        'app/services/sticker_cache_monitor_service.rb',
        'app/services/sticker_error_logger_service.rb'
      ],
      'Controllers' => [
        'app/controllers/api/v1/accounts/stickers_controller.rb',
        'app/controllers/api/v1/accounts/sticker_packs_controller.rb',
        'app/controllers/api/v1/accounts/admin/stickers_controller.rb'
      ],
      'Models' => [
        'app/models/sticker.rb'
      ],
      'Uploaders' => [
        'app/uploaders/sticker_uploader.rb'
      ],
      'Policies' => [
        'app/policies/sticker_policy.rb'
      ]
    }

    # Define expected test files
    test_files = {
      'Service Tests' => [
        'spec/services/sticker_service_spec.rb',
        'spec/services/giphy_service_spec.rb',
        'spec/services/whatsapp/send_sticker_service_spec.rb',
        'spec/services/sticker_cache_monitor_service_spec.rb',
        'spec/services/sticker_error_logger_service_spec.rb'
      ],
      'Controller Tests' => [
        'spec/controllers/api/v1/accounts/stickers_controller_spec.rb',
        'spec/controllers/api/v1/accounts/sticker_packs_controller_spec.rb',
        'spec/controllers/api/v1/accounts/admin/stickers_controller_spec.rb'
      ],
      'Model Tests' => [
        'spec/models/sticker_spec.rb'
      ],
      'Uploader Tests' => [
        'spec/uploaders/sticker_uploader_spec.rb'
      ],
      'Integration Tests' => [
        'spec/integration/whatsapp_sticker_integration_spec.rb'
      ],
      'Frontend Tests' => [
        'app/javascript/dashboard/components/widgets/conversation/StickerPicker/StickerPicker.spec.js',
        'app/javascript/dashboard/components/widgets/conversation/StickerPicker/StickerButton.spec.js',
        'app/javascript/dashboard/components-next/message/bubbles/Sticker.spec.js',
        'app/javascript/dashboard/components-next/message/StickerMessage.integration.spec.js',
        'app/javascript/dashboard/routes/dashboard/settings/stickers/Index.spec.js',
        'app/javascript/dashboard/routes/dashboard/settings/stickers/PackDetails.spec.js'
      ]
    }

    # Check file coverage
    puts "\n📁 File Coverage Analysis:"
    puts "-" * 30

    total_files = 0
    covered_files = 0
    missing_files = []

    sticker_files.each do |category, files|
      puts "\n#{category}:"
      files.each do |file|
        total_files += 1
        if File.exist?(file)
          covered_files += 1
          puts "  ✅ #{file}"
        else
          missing_files << file
          puts "  ❌ #{file} (MISSING)"
        end
      end
    end

    # Check test coverage
    puts "\n🧪 Test Coverage Analysis:"
    puts "-" * 30

    total_tests = 0
    existing_tests = 0
    missing_tests = []

    test_files.each do |category, files|
      puts "\n#{category}:"
      files.each do |file|
        total_tests += 1
        if File.exist?(file)
          existing_tests += 1
          puts "  ✅ #{file}"
        else
          missing_tests << file
          puts "  ❌ #{file} (MISSING)"
        end
      end
    end

    # Calculate coverage percentages
    file_coverage = (covered_files.to_f / total_files * 100).round(2)
    test_coverage = (existing_tests.to_f / total_tests * 100).round(2)

    puts "\n📊 Coverage Summary:"
    puts "=" * 30
    puts "Implementation Files: #{covered_files}/#{total_files} (#{file_coverage}%)"
    puts "Test Files: #{existing_tests}/#{total_tests} (#{test_coverage}%)"

    # Requirements validation
    puts "\n📋 Requirements Validation:"
    puts "-" * 30

    requirements_status = {
      "1. Interface de Seleção de Stickers" => check_requirement_1,
      "2. Integração com Giphy" => check_requirement_2,
      "3. Stickers Personalizados" => check_requirement_3,
      "4. Stickers Recentemente Utilizados" => check_requirement_4,
      "5. Envio Otimizado via WhatsApp Cloud API" => check_requirement_5,
      "6. Processamento e Validação de Imagens" => check_requirement_6,
      "7. Cache e Performance" => check_requirement_7,
      "8. Integração com Interface Existente" => check_requirement_8
    }

    requirements_status.each do |requirement, status|
      icon = status ? "✅" : "❌"
      puts "  #{icon} #{requirement}"
    end

    met_requirements = requirements_status.values.count(true)
    total_requirements = requirements_status.size
    requirements_percentage = (met_requirements.to_f / total_requirements * 100).round(2)

    puts "\n🎯 Final Assessment:"
    puts "=" * 30
    puts "Requirements Met: #{met_requirements}/#{total_requirements} (#{requirements_percentage}%)"
    puts "Overall Readiness: #{overall_readiness_status(file_coverage, test_coverage, requirements_percentage)}"

    if missing_files.any?
      puts "\n⚠️  Missing Implementation Files:"
      missing_files.each { |file| puts "  - #{file}" }
    end

    if missing_tests.any?
      puts "\n⚠️  Missing Test Files:"
      missing_tests.each { |file| puts "  - #{file}" }
    end

    # Recommendations
    puts "\n💡 Recommendations:"
    puts "-" * 20
    
    if file_coverage < 100
      puts "  • Complete missing implementation files"
    end
    
    if test_coverage < 90
      puts "  • Add missing test files to reach >90% coverage"
    end
    
    if requirements_percentage < 100
      puts "  • Address unmet requirements"
    end

    if file_coverage >= 100 && test_coverage >= 90 && requirements_percentage >= 100
      puts "  🎉 Feature is ready for production!"
    end

    puts "\n" + "=" * 60
  end

  private

  def check_requirement_1
    # Interface de Seleção de Stickers
    File.exist?('app/javascript/dashboard/components/widgets/conversation/StickerPicker/StickerPicker.vue') &&
    File.exist?('app/javascript/dashboard/components/widgets/conversation/StickerPicker/StickerButton.vue')
  end

  def check_requirement_2
    # Integração com Giphy
    File.exist?('app/services/giphy_service.rb')
  end

  def check_requirement_3
    # Stickers Personalizados
    File.exist?('app/services/sticker_service.rb') &&
    File.exist?('app/uploaders/sticker_uploader.rb')
  end

  def check_requirement_4
    # Stickers Recentemente Utilizados
    File.exist?('app/services/whatsapp/send_sticker_service.rb')
  end

  def check_requirement_5
    # Envio Otimizado via WhatsApp Cloud API
    File.exist?('app/services/whatsapp/send_sticker_service.rb') &&
    File.exist?('app/services/whatsapp/providers/whatsapp_cloud_service.rb')
  end

  def check_requirement_6
    # Processamento e Validação de Imagens
    File.exist?('app/uploaders/sticker_uploader.rb')
  end

  def check_requirement_7
    # Cache e Performance
    File.exist?('app/services/sticker_cache_monitor_service.rb')
  end

  def check_requirement_8
    # Integração com Interface Existente
    File.exist?('app/javascript/dashboard/components-next/message/bubbles/Sticker.vue')
  end

  def overall_readiness_status(file_coverage, test_coverage, requirements_percentage)
    if file_coverage >= 100 && test_coverage >= 90 && requirements_percentage >= 100
      "🟢 READY FOR PRODUCTION"
    elsif file_coverage >= 80 && test_coverage >= 70 && requirements_percentage >= 80
      "🟡 NEEDS MINOR IMPROVEMENTS"
    else
      "🔴 NEEDS SIGNIFICANT WORK"
    end
  end
end