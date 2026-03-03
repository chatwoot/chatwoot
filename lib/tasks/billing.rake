namespace :billing do
  desc 'Migrate existing accounts without subscriptions to Basic plan (idempotent)'
  task migrate_to_basic: :environment do
    migrated = 0
    skipped = 0

    Account.where(status: :active).find_each do |account|
      if account.payment_processor&.subscription.present?
        skipped += 1
        next
      end

      account.grant_complimentary!(plan_key: 'basic_monthly')
      migrated += 1
    end

    puts "Billing migration complete: #{migrated} migrated, #{skipped} skipped (already subscribed)"
  end
end
