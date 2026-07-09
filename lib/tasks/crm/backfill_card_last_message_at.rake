# Backfills crm_cards.last_message_at (and last_activity_at) away from the contaminated
# fallback (conversation.last_activity_at, bumped by ANY message including system activity
# such as assignee/team changes) so it reflects only the last REAL message (Message.chat:
# not activity, not private) of the card's linked conversation(s). NULL when the card has
# no real message yet — the "Inatividade" filter (Crm::Cards::SharedFilters#apply_stale_filter)
# already treats NULL as stale.
#
# Scope: ALL cards regardless of status (open/won/lost/archived) — correcting won/lost/
# archived cards too is strictly safer than leaving stale data behind (they still surface
# in reports/exports keyed off last_message_at).
#
# DRY_RUN by default (report only):
#   bundle exec rails crm:backfill_card_last_message_at
# Apply:
#   APPLY=true bundle exec rails crm:backfill_card_last_message_at
namespace :crm do
  desc 'Backfills crm_cards.last_message_at/last_activity_at from real (non-activity, non-private) ' \
       'messages. DRY_RUN by default; APPLY=true to write.'
  task backfill_card_last_message_at: :environment do
    apply = ActiveModel::Type::Boolean.new.cast(ENV.fetch('APPLY', nil)) || false
    puts "[crm][backfill_card_last_message_at] mode=#{apply ? 'APPLY' : 'DRY_RUN'} scope=all_statuses"

    total = 0
    contaminated = 0
    fixed = 0

    Crm::Card.includes(:linked_conversations).find_in_batches(batch_size: 500) do |batch|
      batch.each do |card|
        total += 1
        correct_value = CrmCardLastMessageBackfill.correct_last_message_at(card)
        next if CrmCardLastMessageBackfill.matches?(card, correct_value)

        contaminated += 1
        next unless apply

        # Bypasses callbacks/validations on purpose: pure data correction, no business
        # event happened (mirrors lib/tasks/ctwa_cleanup.rake's update_column usage).
        # rubocop:disable Rails/SkipsModelValidations
        card.update_columns(last_message_at: correct_value, last_activity_at: correct_value)
        # rubocop:enable Rails/SkipsModelValidations
        fixed += 1
      end
    end

    if apply
      puts "[crm][backfill_card_last_message_at][done] total=#{total} contaminated=#{contaminated} fixed=#{fixed}"
    else
      puts "[crm][backfill_card_last_message_at][preflight] total=#{total} contaminated=#{contaminated} " \
           "to_fix=#{contaminated} — DRY_RUN, nothing changed. Re-run with APPLY=true to write."
    end
  end
end

# Helper for crm:backfill_card_last_message_at. Top-level on purpose: rake files load
# outside Zeitwerk, so we don't inject constants into the autoloaded Crm namespace.
module CrmCardLastMessageBackfill
  module_function

  # Aggregates across every conversation linked to the card (primary_conversation +
  # crm_card_conversations), same fan-out as Crm::Cards::PayloadBuilder.aggregated_campaigns_for,
  # so a card with several linked conversations picks up the latest real message of any of them.
  def correct_last_message_at(card)
    conversation_ids = (card.linked_conversations.to_a.map(&:id) + [card.conversation_id]).compact.uniq
    return nil if conversation_ids.empty?

    Message.chat.where(conversation_id: conversation_ids).maximum(:created_at)
  end

  def matches?(card, correct_value)
    card.last_message_at.to_i == correct_value.to_i
  end
end
