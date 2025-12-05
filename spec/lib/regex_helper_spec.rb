require 'rails_helper'

RSpec.describe RegexHelper do
  describe 'WHATSAPP_GROUP_JID_REGEX' do
    it 'matches valid group JIDs' do
      valid_group_jids = [
        '120363025246125486@g.us',
        '1234567890@g.us',
        '123456789012345678@g.us'
      ]

      valid_group_jids.each do |jid|
        expect(RegexHelper::WHATSAPP_GROUP_JID_REGEX.match?(jid)).to be(true), "Expected #{jid} to match"
      end
    end

    it 'rejects invalid group JIDs' do
      invalid_group_jids = [
        '123456789', # missing @g.us
        '123456789@s.whatsapp.net', # wrong suffix
        '123456789@g.us.invalid', # extra suffix
        'abc123456789@g.us', # contains letters
        '12345678@g.us', # too short (less than 10 digits)
        '1234567890123456789@g.us', # too long (more than 18 digits)
        '@g.us', # no digits
        '123456789@g.', # incomplete suffix
        '123456789@.us' # malformed suffix
      ]

      invalid_group_jids.each do |jid|
        expect(RegexHelper::WHATSAPP_GROUP_JID_REGEX.match?(jid)).to be(false), "Expected #{jid} to not match"
      end
    end
  end

  describe 'WHATSAPP_CHANNEL_REGEX' do
    it 'still matches individual WhatsApp numbers' do
      valid_numbers = %w[
        5511999887766
        1234567890
        123456789012345
      ]

      valid_numbers.each do |number|
        expect(RegexHelper::WHATSAPP_CHANNEL_REGEX.match?(number)).to be(true), "Expected #{number} to match"
      end
    end
  end

  describe 'WHATSAPP_WEB_INDIVIDUAL_JID_REGEX' do
    it 'matches valid WhatsApp Web individual JIDs' do
      valid_jids = [
        '5511999887766@s.whatsapp.net',
        '1234567890@s.whatsapp.net',
        '123456789012345@s.whatsapp.net'
      ]

      valid_jids.each do |jid|
        expect(RegexHelper::WHATSAPP_WEB_INDIVIDUAL_JID_REGEX.match?(jid)).to be(true), "Expected #{jid} to match"
      end
    end

    it 'rejects invalid WhatsApp Web individual JIDs' do
      invalid_jids = [
        '123456789', # missing @s.whatsapp.net
        '123456789@g.us', # wrong suffix
        '123456789@s.whatsapp.net.invalid', # extra suffix
        'abc123456789@s.whatsapp.net', # contains letters
        '123456789@s.whatsapp', # incomplete suffix
        '123456789@whatsapp.net' # malformed suffix
      ]

      invalid_jids.each do |jid|
        expect(RegexHelper::WHATSAPP_WEB_INDIVIDUAL_JID_REGEX.match?(jid)).to be(false), "Expected #{jid} to not match"
      end
    end
  end
end
