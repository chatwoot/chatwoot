module RegexHelper
  # user https://rubular.com/ to quickly validate your regex

  # the following regext needs atleast one character which should be
  # valid unicode letter, unicode number, underscore, hyphen
  # shouldn't start with a underscore or hyphen
  UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE = Regexp.new('\A[\p{L}\p{N}]+[\p{L}\p{N}_-]+\Z')
  # Regex to match mention markdown links and extract display names
  # Matches: [@display name](mention://user|team/id/url_encoded_name)
  # Captures: 1) @display name (including emojis), 2) url_encoded_name
  # Uses [^]]+ to match any characters except ] in display name to support emojis
  # NOTE: Still used by Slack integration (lib/integrations/slack/send_on_slack_service.rb)
  # while notifications use CommonMarker for better markdown processing
  MENTION_REGEX = Regexp.new('\[(@[^\\]]+)\]\(mention://(?:user|team)/\d+/([^)]+)\)')

  TWILIO_CHANNEL_SMS_REGEX = Regexp.new('^\+\d{1,15}\z')
  TWILIO_CHANNEL_WHATSAPP_REGEX = Regexp.new('^whatsapp:\+\d{1,15}\z')
  WHATSAPP_BSUID_REGEX = Regexp.new('^[A-Za-z]{2}\.(?:ENT\.)?[A-Za-z0-9]{1,128}\z')
  # Supports:
  # - WhatsApp phone identifiers: 1234567890
  # - Business-scoped user identifiers (BSUID): US.13491208655302741918
  # - Parent BSUID: US.ENT.11815799212886844830
  WHATSAPP_CHANNEL_REGEX = Regexp.new('^(?:\d{1,15}|[A-Za-z]{2}\.(?:ENT\.)?[A-Za-z0-9]{1,128})\z')
end
