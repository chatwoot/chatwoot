module RegexHelper
  # user https://rubular.com/ to quickly validate your regex

  # the following regext needs atleast one character which should be
  # valid unicode letter, unicode number, underscore, hyphen
  # shouldn't start with a underscore or hyphen
  UNICODE_CHARACTER_NUMBER_HYPHEN_UNDERSCORE = Regexp.new('\A[\p{L}\p{N}]+[\p{L}\p{N}_-]+\Z')
  MENTION_REGEX = Regexp.new('\[(@[\w_. ]+)\]\(mention://(?:user|team)/\d+/(.*?)+\)')

  TWILIO_CHANNEL_SMS_REGEX = Regexp.new('^\+\d{1,15}\z')
  TWILIO_CHANNEL_WHATSAPP_REGEX = Regexp.new('^whatsapp:\+\d{1,15}\z')
  WHATSAPP_CHANNEL_REGEX = Regexp.new('^\d{1,15}\z')
end
