# Feature-flag gate for the WhatsApp Coexistence messaging-history sync pipeline.
# The whole pipeline (webhook subscription fields, sync trigger, and inbound
# history/state-sync handlers) stays behind this single ENV flag, OFF by default.
module Whatsapp::HistorySync
  module_function

  def enabled?
    ActiveModel::Type::Boolean.new.cast(ENV.fetch('WHATSAPP_HISTORY_SYNC_ENABLED', false))
  end
end
