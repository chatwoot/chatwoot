# frozen_string_literal: true

namespace :business_rules do
  desc 'Migrate conversation_required_attributes into business_rules (idempotent). DRY_RUN=1 to preview.'
  task migrate_required_attributes: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', '0'))
    result = BusinessRules::MigrateRequiredAttributesService.perform!(dry_run: dry_run)
    puts "dry_run=#{result[:dry_run]} migrated=#{result[:migrated]} skipped=#{result[:skipped]}"
  end
end
