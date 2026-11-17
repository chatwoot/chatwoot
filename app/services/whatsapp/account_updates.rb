# Meta's `account_update` changes describe a partner relationship on a WABA, not a phone number, and Meta can batch
# them with message or call changes in one delivery. These helpers split them out so each part is handled on its own.
module Whatsapp::AccountUpdates
  module_function

  # Each account_update change, with the id of the entry it arrived in. PARTNER_* events name the WABA in waba_info
  # (their entry.id is our partner business), while ACCOUNT_OFFBOARDED and ACCOUNT_RECONNECTED name it only in entry.id.
  def changes(payload)
    return [] unless payload[:object] == 'whatsapp_business_account'

    Array(payload[:entry]).flat_map do |entry|
      Array(entry[:changes]).select { |change| account_update?(change) }.map { |change| change.merge(entry_id: entry[:id]) }
    end
  end

  # The payload without its account_update changes, or nil when nothing else is left in it.
  def without(payload)
    return payload unless payload[:object] == 'whatsapp_business_account' && changes(payload).any?

    entries = Array(payload[:entry]).filter_map do |entry|
      remaining = Array(entry[:changes]).reject { |change| account_update?(change) }
      entry.merge(changes: remaining) if remaining.any?
    end
    payload.merge(entry: entries) if entries.any?
  end

  # Other account_update events are ignored.
  def process(change)
    value = change[:value] || {}

    case value[:event]
    when 'PARTNER_REMOVED'
      Whatsapp::PartnerRemovedService.new(value.dig(:waba_info, :waba_id), reason: value.dig(:disconnection_info, :reason)).perform
    when 'ACCOUNT_OFFBOARDED'
      Whatsapp::CoexistenceOffboarding.offboarded(change[:entry_id])
    when 'ACCOUNT_RECONNECTED'
      Whatsapp::CoexistenceOffboarding.reconnected(change[:entry_id])
    end
  end

  def account_update?(change)
    change[:field] == 'account_update'
  end
end
