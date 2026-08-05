import {
  findConnectedInbox,
  isChannelConnected,
} from '../../inbox-setup/channelMatchers';

const WHATSAPP = { id: 1, channel_type: 'Channel::Whatsapp' };
const GMAIL = { id: 2, channel_type: 'Channel::Email', provider: 'google' };
const OUTLOOK = {
  id: 3,
  channel_type: 'Channel::Email',
  provider: 'microsoft',
};

describe('channelMatchers', () => {
  describe('findConnectedInbox', () => {
    it('returns the inbox sharing the channel type', () => {
      expect(
        findConnectedInbox([WHATSAPP], { channel_type: 'Channel::Whatsapp' })
      ).toBe(WHATSAPP);
    });

    it('matches email inboxes on provider', () => {
      expect(
        findConnectedInbox([OUTLOOK, GMAIL], {
          channel_type: 'Channel::Email',
          provider: 'google',
        })
      ).toBe(GMAIL);
    });

    it('does not match a different email provider', () => {
      expect(
        findConnectedInbox([OUTLOOK], {
          channel_type: 'Channel::Email',
          provider: 'google',
        })
      ).toBeUndefined();
    });

    it('returns undefined when nothing matches', () => {
      expect(
        findConnectedInbox([WHATSAPP], { channel_type: 'Channel::Telegram' })
      ).toBeUndefined();
    });
  });

  describe('isChannelConnected', () => {
    it('is true when a matching inbox exists', () => {
      expect(
        isChannelConnected([WHATSAPP], { channel_type: 'Channel::Whatsapp' })
      ).toBe(true);
    });

    it('is false when no inbox matches', () => {
      expect(isChannelConnected([WHATSAPP], GMAIL)).toBe(false);
    });

    it('is false for a channel without an inbox stub', () => {
      expect(isChannelConnected([WHATSAPP], undefined)).toBe(false);
    });
  });
});
