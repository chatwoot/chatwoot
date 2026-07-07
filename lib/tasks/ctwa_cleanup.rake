# CTWA multi-touch backfill (step 2 and 3 of the deploy order — run AFTER the code +
# index are live):
#
#   bundle exec rails ctwa:convert_legacy                           # re-runnable, idempotent
#   bundle exec rails ctwa:remove_meta_ctwa_label                   # DRY_RUN default (preflight only)
#   DRY_RUN=0 ACCOUNT_IDS=6,18 bundle exec rails ctwa:remove_meta_ctwa_label
#
# Rollback of the label cleanup (zero information loss — the removed set is exactly
# {conversation has `campaign` attribute AND was tagged}, fully reconstructible):
#   account.labels.create!(title: 'meta_ctwa', color: '#25D366', show_on_sidebar: true)
#   account.conversations.where("additional_attributes ? 'campaign'")
#          .find_each { |c| c.add_labels('meta_ctwa') }
namespace :ctwa do
  desc 'Converts legacy single-touch CTWA campaign records to the multi-touch shape (idempotent)'
  task convert_legacy: :environment do
    scope = Conversation.where("additional_attributes ? 'campaign' AND NOT additional_attributes ? 'campaign_touches'")
    puts "[ctwa][convert_legacy][preflight] legacy=#{scope.count}"

    results = Hash.new(0)
    scope.find_in_batches(batch_size: 500) do |batch|
      batch.each { |conversation| results[CtwaLegacyConversion.convert(conversation)] += 1 }
    end
    puts "[ctwa][convert_legacy][done] converted=#{results[:converted]} skipped=#{results[:skipped]} remaining_legacy=#{scope.count}"
  end

  desc 'Removes the legacy meta_ctwa label from CTWA conversations (DRY_RUN=1 default; DRY_RUN=0 to execute)'
  task remove_meta_ctwa_label: :environment do
    dry_run = ENV['DRY_RUN'] != '0'
    accounts = CtwaMetaCtwaLabelCleanup.target_accounts(ENV.fetch('ACCOUNT_IDS', nil))
    puts "[ctwa][remove_meta_ctwa_label] dry_run=#{dry_run} accounts=#{accounts.map(&:id).inspect}"

    CtwaMetaCtwaLabelCleanup.preflight_references!(accounts)

    leftovers = accounts.sum { |account| CtwaMetaCtwaLabelCleanup.cleanup_account(account, dry_run: dry_run) }
    if dry_run
      puts '[ctwa][remove_meta_ctwa_label] DRY_RUN — nothing changed. Re-run with DRY_RUN=0 to execute.'
    elsif leftovers.positive?
      abort "[ctwa][remove_meta_ctwa_label] INCOMPLETE — #{leftovers} eligible tagging(s) left. Fix the cause and re-run."
    end
  end
end

# Helper for ctwa:convert_legacy. Top-level on purpose: rake files load outside Zeitwerk,
# so we don't inject constants into the autoloaded Ctwa namespace.
module CtwaLegacyConversion
  module_function

  # Lock + re-check: a live webhook can convert this row (and append a fresh touch)
  # between the batch load and this write — overwriting with our stale snapshot would
  # drop that touch. Under the lock the discriminator decides atomically.
  def convert(conversation)
    conversation.with_lock do
      next :skipped if conversation.additional_attributes.key?('campaign_touches')

      # Same projection the builder applies on migrate-on-write: slim touch (no body)
      # stamped with the conversation creation time, origin gains touched_at, mirror
      # rebuilt from the touches. Round-trips identically with Ctwa::CampaignBuilder.
      touches = Ctwa::CampaignBuilder.existing_touches(conversation)
      next :skipped if touches.empty? # blank `campaign` hash — nothing to seed

      # Backfill write: cache-only effect wanted, no Conversation callbacks/webhooks.
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_column(:additional_attributes,
                                 Ctwa::CampaignBuilder.campaign_attributes(conversation, touches.first, touches))
      # rubocop:enable Rails/SkipsModelValidations
      :converted
    end
  end
end

# Helper for ctwa:remove_meta_ctwa_label — mirrors the Labels::DestroyService mechanics
# (update cached_label_list bypassing callbacks + delete taggings directly) but scoped to
# conversations that carry the `campaign` attribute, so manually applied meta_ctwa labels
# on unrelated conversations are preserved. Top-level on purpose: rake files load outside
# Zeitwerk, so we don't inject constants into the autoloaded Ctwa namespace.
module CtwaMetaCtwaLabelCleanup
  module_function

  LABEL_TITLE = 'meta_ctwa'.freeze

  def target_accounts(raw_account_ids)
    account_ids = raw_account_ids.to_s.split(',').map(&:strip).reject(&:empty?).map(&:to_i).presence
    return Account.where(id: account_ids).to_a if account_ids

    Account.where(id: Label.where(title: LABEL_TITLE).select(:account_id)).to_a
  end

  # Aborts when any custom view/folder, automation rule or macro still references the
  # label — those would silently stop matching after the cleanup, so the operator must
  # migrate them first.
  def preflight_references!(accounts)
    references = accounts.flat_map { |account| account_references(account) }
    return if references.empty?

    references.each { |ref| puts "[ctwa][remove_meta_ctwa_label][blocked] #{ref}" }
    abort "[ctwa][remove_meta_ctwa_label] ABORTED — #{references.size} reference(s) to '#{LABEL_TITLE}' " \
          'in custom views/automation rules/macros. Migrate them before re-running.'
  end

  def account_references(account)
    like = "%#{LABEL_TITLE}%"
    account.custom_filters.where('query::text ILIKE ?', like)
           .map { |f| "account=#{account.id} custom_filter=#{f.id} (#{f.name})" } +
      account.automation_rules.where('conditions::text ILIKE ? OR actions::text ILIKE ?', like, like)
             .map { |r| "account=#{account.id} automation_rule=#{r.id} (#{r.name})" } +
      account.macros.where('actions::text ILIKE ?', like)
             .map { |m| "account=#{account.id} macro=#{m.id} (#{m.name})" }
  end

  # Returns the number of eligible taggings left for the account (0 = clean).
  def cleanup_account(account, dry_run:)
    tagged_total = tagged_conversations(account).count
    eligible_count = eligible_conversations(account).count
    puts "[ctwa][remove_meta_ctwa_label][preflight] account=#{account.id} tagged=#{tagged_total} " \
         "eligible=#{eligible_count} manual_kept=#{tagged_total - eligible_count}"
    return 0 if dry_run

    remove_taggings(account)
    destroy_label_when_clean(account)

    remaining = eligible_conversations(account).count
    puts "[ctwa][remove_meta_ctwa_label][postflight] account=#{account.id} eligible_remaining=#{remaining}"
    remaining
  end

  def remove_taggings(account)
    eligible_conversations(account).find_in_batches(batch_size: 500) do |batch|
      batch.each { |conversation| strip_cached_label(conversation) }
      label_taggings('Conversation').where(taggable_id: batch.map(&:id)).delete_all
    end
    # No taggings_count to fix up: the app runs with ActsAsTaggableOn.tags_counter = false
    # (config/initializers/acts_as_taggable_on.rb), so the counter cache is never maintained.
  end

  def strip_cached_label(conversation)
    label_list = conversation.label_list.dup
    label_list.remove(LABEL_TITLE)
    # Cache-only effect, same bypass as Labels::DestroyService (no callbacks/events).
    # rubocop:disable Rails/SkipsModelValidations
    conversation.update_column(:cached_label_list, label_list.join("#{ActsAsTaggableOn.delimiter} "))
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Deletes the account's Label record only once no tagging remains in the account
  # (conversations AND contacts — the tag row itself is global/cross-account and is
  # never deleted). A manual tagging left behind keeps the Label alive on purpose.
  def destroy_label_when_clean(account)
    remaining = label_taggings('Conversation').where(taggable_id: account.conversations.select(:id)).count +
                label_taggings('Contact').where(taggable_id: account.contacts.select(:id)).count
    return puts "[ctwa][remove_meta_ctwa_label] account=#{account.id} label kept (#{remaining} tagging(s) remain)" if remaining.positive?

    account.labels.find_by(title: LABEL_TITLE)&.destroy!
    puts "[ctwa][remove_meta_ctwa_label] account=#{account.id} label record deleted"
  end

  def tagged_conversations(account)
    account.conversations.tagged_with(LABEL_TITLE)
  end

  def eligible_conversations(account)
    tagged_conversations(account).where("additional_attributes ? 'campaign'")
  end

  def label_taggings(taggable_type)
    ActsAsTaggableOn::Tagging
      .joins(:tag)
      .where(context: 'labels', taggable_type: taggable_type, tags: { name: LABEL_TITLE })
  end
end
