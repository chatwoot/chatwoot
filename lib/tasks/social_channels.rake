namespace :social_channels do
  desc 'Backfill provider names. Options: DRY_RUN, ACCOUNT_ID, PROVIDER, LIMIT, AFTER_ID, DELAY_SECONDS. LIMIT/AFTER_ID require PROVIDER'
  task backfill_provider_names: :environment do
    SocialChannels::ProviderNameBackfillService.new(
      account_id: ENV.fetch('ACCOUNT_ID', nil),
      provider: ENV.fetch('PROVIDER', nil),
      limit: ENV.fetch('LIMIT', nil),
      after_id: ENV.fetch('AFTER_ID', nil),
      delay_seconds: ENV.fetch('DELAY_SECONDS', 1),
      dry_run: ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', true))
    ).perform
  end
end
