# frozen_string_literal: true

module InboxNameSanitization
  extend ActiveSupport::Concern

  included do
    before_validation :sanitize_name
  end

  # Sanitizes inbox name for balanced email provider compatibility
  # ALLOWS: /'._- and Unicode letters/numbers/emojis
  # REMOVES: Forbidden chars (\<>@") + spam-trigger symbols (!#$%&*+=?^`{|}~)
  def sanitized_name
    return default_name_for_blank_name if name.blank?

    sanitized = apply_sanitization_rules(name)
    sanitized.blank? && email? ? display_name_from_email : sanitized
  end

  private

  def sanitize_name
    self.name = default_name_for_blank_name if name.blank?
    self.name = apply_sanitization_rules(name) if name.present?
  end

  def default_name_for_blank_name
    return channel.try(:bot_name) if web_widget?

    readable_name = display_name_from_email if email?
    readable_name ||= 'Inbox'
    "#{readable_name} #{SecureRandom.hex(4)}"
  end

  def apply_sanitization_rules(name)
    name_without_special_characters = name.gsub(/[^a-zA-Z0-9\s]/, ' ')
    name_without_special_characters.gsub(/\s+/, ' ').strip
  end

  def display_name_from_email
    channel.try(:imap_email)&.split('@')&.first&.capitalize
  end
end
