# frozen_string_literal: true

module InboxNameSanitization
  extend ActiveSupport::Concern

  included do
    before_validation :sanitize_name, unless: :new_record?
    before_save :ensure_name_present
  end

  # Sanitizes inbox name for balanced email provider compatibility
  # ALLOWS: /'._- and Unicode letters/numbers/emojis
  # REMOVES: Forbidden chars (\<>@") + spam-trigger symbols (!#$%&*+=?^`{|}~)
  def sanitized_name
    return handle_blank_name if name.blank?

    sanitized = apply_sanitization_rules(name)
    return sanitized if sanitized.present?

    email? ? (display_name_from_email || '') : ''
  end

  private

  def handle_blank_name
    email? ? (display_name_from_email || '') : ''
  end

  def sanitize_name
    self.name = apply_sanitization_rules(name) if name.present?
  end

  def ensure_name_present
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
    # Remove forbidden characters and spam-trigger symbols
    # Keep: letters, numbers, spaces, /'._- and Unicode characters (including emojis)
    sanitized = name.gsub(/[\\<>@"!#$%&*+=?^`{|}~;:]/, '')
    # Normalize whitespace
    sanitized = sanitized.gsub(/\s+/, ' ')
    # Remove leading and trailing non-word characters (but keep Unicode including emojis)
    # Use negative lookahead to exclude emoji ranges
    sanitized = sanitized.gsub(%r{\A[^\p{L}\p{N}\p{So}\p{Sc}\s'/_.-]+|[^\p{L}\p{N}\p{So}\p{Sc}\s'/_.-]+\z}, '')
    sanitized.strip
  end

  def display_name_from_email
    email_address = channel.try(:imap_email) || channel.try(:email)
    return nil unless email_address

    local_part = email_address.split('@').first
    return nil unless local_part

    # Convert underscores and hyphens to spaces and capitalize each word
    local_part.gsub(/[_-]/, ' ').split.map(&:capitalize).join(' ')
  end
end
