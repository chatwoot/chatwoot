# Adds an optional expiry to the contact `blocked` flag.
#
# A block with `blocked_until` set is lifted lazily the first time `blocked?`
# is evaluated after that time, so no scheduler is required and every caller
# (`Conversation#muted?`, notification builder, channel services, ...) sees a
# consistent answer.
module ContactBlockable
  extend ActiveSupport::Concern

  def blocked?
    return false unless super
    return true if blocked_until.blank? || blocked_until.future?

    update_columns(blocked: false, blocked_until: nil) if persisted? # rubocop:disable Rails/SkipsModelValidations
    false
  end
end
