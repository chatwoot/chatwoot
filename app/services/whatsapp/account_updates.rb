# Meta's `account_update` changes describe a partner relationship on a WABA, not a phone number, and Meta can batch
# them with message or call changes in one delivery. These helpers split them out so each part is handled on its own.
module Whatsapp::AccountUpdates
  module_function

  def changes(payload)
    return [] unless payload[:object] == 'whatsapp_business_account'

    Array(payload[:entry]).flat_map { |entry| Array(entry[:changes]) }.select { |change| account_update?(change) }
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

  def account_update?(change)
    change[:field] == 'account_update'
  end
end
