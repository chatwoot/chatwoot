# Preview by default. ACCOUNT_ID=<id> APPLY=true bundle exec rails runner script/enable_individual_conversation_reads.rb
account = Account.find(ENV.fetch('ACCOUNT_ID'))
feature = Conversations::ReadStateService::FEATURE_FLAG
puts({ account_id: account.id, enabled: account.feature_enabled?(feature), conversations: account.conversations.count,
       preserve_existing_read_state: true, apply: ENV['APPLY'] == 'true' }.to_json)

if ENV['APPLY'] == 'true'
  account.with_lock do
    unless account.feature_enabled?(feature)
      # Freeze the shared marker before switching readers. Never reset existing personal receipts on reactivation.
      unless account.conversation_read_states.exists?
        account.conversations.update_all('read_baseline_at = agent_last_seen_at') # rubocop:disable Rails/SkipsModelValidations
      end
      account.enable_features!(feature)
    end
  end
  raise 'Individual read state was not enabled' unless account.reload.feature_enabled?(feature)

  Conversations::UnreadCounts::FilteredCountInvalidator.new(account).conversation_changed!
  puts({ applied: true, account_id: account.id, enabled: true }.to_json)
end
