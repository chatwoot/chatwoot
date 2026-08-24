module RegexHelper
  # user https://rubular.com/ to quickly validate your regex

  # the following regext needs atleast one character which should be
  # valid unicode letter, unicode number, underscore, hyphen
  # shouldn't start with a underscore or hyphen
  # \z (not \Z) anchors strictly to the end of the string -- \Z would also accept a single
  # trailing "\n", which would let a title like "hello_world\n" pass this validation.
  UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE = Regexp.new('\A[\p{L}\p{N}]+[\p{L}\p{N}_-]+\z')
  # Regex to match mention markdown links and extract display names
  # Matches: [@display name](mention://user|team/id/url_encoded_name)
  # Captures: 1) @display name (including emojis), 2) url_encoded_name
  # Uses [^]]+ to match any characters except ] in display name to support emojis
  # NOTE: Still used by Slack integration (lib/integrations/slack/send_on_slack_service.rb)
  # while notifications use CommonMarker for better markdown processing
  MENTION_REGEX = Regexp.new('\[(@[^\\]]+)\]\(mention://(?:user|team)/\d+/([^)]+)\)')

  TWILIO_CHANNEL_SMS_REGEX = Regexp.new('\A\+\d{1,15}\z')
  WHATSAPP_BSUID_PATTERN = '[A-Z]{2}\.(?:ENT\.)?[A-Za-z0-9]{1,128}'.freeze
  WHATSAPP_WAMID_TOKEN_PATTERN = '(?<![0-9a-f])(?:[0-9a-f]{32}|[0-9a-f]{20})(?![0-9a-f])'.freeze
  WHATSAPP_BSUID_REGEX = Regexp.new("\\A#{WHATSAPP_BSUID_PATTERN}\\z")
  WHATSAPP_WAMID_TOKEN_REGEX = Regexp.new(WHATSAPP_WAMID_TOKEN_PATTERN, Regexp::IGNORECASE)
  TWILIO_CHANNEL_WHATSAPP_REGEX = Regexp.new("\\A(?:whatsapp:\\+\\d{1,15}|whatsapp:#{WHATSAPP_BSUID_PATTERN})\\z")
  WHATSAPP_CHANNEL_REGEX = Regexp.new("\\A(?:\\d{1,15}|#{WHATSAPP_BSUID_PATTERN})\\z")
end
