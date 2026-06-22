import { defineComponent, h } from 'vue';
import { createStore } from 'vuex';
import { mount } from '@vue/test-utils';
import { useRoute } from 'vue-router';
import { useDetectedChannels } from '../../inbox-setup/useDetectedChannels';

vi.mock('vue-router');

// Mounts the composable against a real store and the real useAccount (only
// useRoute and the underlying getters are faked), so a change to how useAccount
// resolves the current account is exercised here too. The real ./constants are
// used, so assertions validate against the actual channel identity (label keys,
// channel_type, social ordering) derived from CHANNEL_LIST.
const mountComposable = ({ brandInfo, inboxes = [] } = {}) => {
  const store = createStore({
    modules: {
      accounts: {
        namespaced: true,
        getters: {
          getAccount: () => () => ({
            id: 1,
            custom_attributes: { brand_info: brandInfo },
          }),
        },
      },
      inboxes: {
        namespaced: true,
        getters: { getInboxes: () => inboxes },
      },
    },
  });

  let result;
  const Component = defineComponent({
    setup() {
      result = useDetectedChannels();
      return () => h('div');
    },
  });
  mount(Component, { global: { plugins: [store] } });
  return result;
};

beforeEach(() => {
  useRoute.mockReturnValue({ params: { accountId: '1' } });
  // Configure the installation OAuth credentials so detected channels aren't
  // hidden by the config gate; individual tests clear this to assert hiding.
  window.chatwootConfig = {
    fbAppId: 'fb',
    instagramAppId: 'ig',
    tiktokAppId: 'tt',
    whatsappAppId: 'wa',
    whatsappConfigurationId: 'wa-config',
  };
});

afterEach(() => {
  delete window.chatwootConfig;
});

describe('useDetectedChannels', () => {
  describe('displayedChannels', () => {
    it('maps detected socials with a url to channel rows', () => {
      const { displayedChannels } = mountComposable({
        brandInfo: {
          socials: [
            { type: 'whatsapp', url: 'https://wa.me/1-415-555-2671' },
            { type: 'instagram', url: 'https://instagram.com/acme' },
          ],
        },
      });

      expect(displayedChannels.value).toEqual([
        {
          type: 'whatsapp',
          handle: '+14155552671',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE',
          inbox: { channel_type: 'Channel::Whatsapp' },
        },
        {
          type: 'instagram',
          handle: '@acme',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE',
          inbox: { channel_type: 'Channel::Instagram' },
        },
      ]);
    });

    it('skips socials without a url or with an unknown type', () => {
      const { displayedChannels } = mountComposable({
        brandInfo: {
          socials: [
            { type: 'telegram' }, // no url
            { type: 'mastodon', url: 'https://mastodon.social/@acme' }, // unknown
            { type: 'tiktok', url: 'https://tiktok.com/@acme' },
          ],
        },
      });

      expect(displayedChannels.value.map(channel => channel.type)).toEqual([
        'tiktok',
      ]);
    });

    it('uses the raw path for line and falls back to empty on a bad url', () => {
      const { displayedChannels } = mountComposable({
        brandInfo: {
          socials: [
            { type: 'line', url: 'https://line.me/acme' },
            { type: 'facebook', url: 'not-a-url' },
          ],
        },
      });

      expect(displayedChannels.value).toEqual([
        {
          type: 'line',
          handle: 'acme',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE',
          inbox: { channel_type: 'Channel::Line' },
        },
        {
          type: 'facebook',
          handle: '',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE',
          inbox: { channel_type: 'Channel::FacebookPage' },
        },
      ]);
    });

    it('omits the detected email channel while email is disabled for this phase', () => {
      const { displayedChannels } = mountComposable({
        brandInfo: {
          email_provider: 'google',
          email: 'support@acme.com',
          socials: [{ type: 'whatsapp', url: 'https://wa.me/14155552671' }],
        },
      });

      expect(displayedChannels.value.map(channel => channel.type)).toEqual([
        'whatsapp',
      ]);
    });

    it('falls back to the default channel suggestions when nothing is detected', () => {
      const { displayedChannels } = mountComposable({ brandInfo: undefined });

      // The configured mainstream channels, with no detected handle.
      expect(displayedChannels.value).toEqual([
        {
          type: 'whatsapp',
          handle: '',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE',
          inbox: { channel_type: 'Channel::Whatsapp' },
        },
        {
          type: 'facebook',
          handle: '',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE',
          inbox: { channel_type: 'Channel::FacebookPage' },
        },
        {
          type: 'instagram',
          handle: '',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE',
          inbox: { channel_type: 'Channel::Instagram' },
        },
      ]);
    });

    it('gates the default suggestions by installation config, keeping the list non-empty', () => {
      window.chatwootConfig = {}; // no OAuth credentials configured
      const { displayedChannels } = mountComposable({ brandInfo: undefined });

      // Only the credential-free defaults survive (Telegram, LINE).
      expect(displayedChannels.value.map(channel => channel.type)).toEqual([
        'telegram',
        'line',
      ]);
    });

    it('hides detected channels whose installation OAuth credentials are missing', () => {
      window.chatwootConfig = {}; // nothing configured
      const { displayedChannels } = mountComposable({
        brandInfo: {
          socials: [
            { type: 'facebook', url: 'https://facebook.com/acme' },
            { type: 'line', url: 'https://line.me/acme' },
          ],
        },
      });

      // Facebook needs fbAppId (absent → hidden); LINE needs no install credential.
      expect(displayedChannels.value.map(channel => channel.type)).toEqual([
        'line',
      ]);
    });
  });

  describe('remainingChannels', () => {
    it('returns the platforms not already shown as default rows', () => {
      // Nothing detected → displayed falls back to the defaults (WhatsApp,
      // Facebook, Instagram), so the footer previews the remaining platforms.
      const { remainingChannels } = mountComposable({ brandInfo: {} });

      expect(remainingChannels.value).toEqual([
        {
          type: 'line',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE',
          inbox: { channel_type: 'Channel::Line' },
        },
        {
          type: 'telegram',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.TITLE',
          inbox: { channel_type: 'Channel::Telegram' },
        },
        {
          type: 'tiktok',
          labelKey: 'INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.TITLE',
          inbox: { channel_type: 'Channel::Tiktok' },
        },
      ]);
    });

    it('excludes already-detected socials, preserving order', () => {
      const { remainingChannels } = mountComposable({
        brandInfo: {
          socials: [{ type: 'whatsapp', url: 'https://wa.me/14155552671' }],
        },
      });

      expect(remainingChannels.value.map(channel => channel.type)).toEqual([
        'facebook',
        'line',
        'instagram',
      ]);
    });

    it('excludes channels whose installation OAuth credentials are missing', () => {
      window.chatwootConfig = {}; // nothing configured
      const { remainingChannels } = mountComposable({ brandInfo: {} });

      // The only configured channels (Telegram, LINE) are shown as default rows,
      // and every other platform is gated out — so nothing remains for the footer.
      expect(remainingChannels.value).toEqual([]);
    });
  });

  describe('connectedInbox', () => {
    it('returns the real inbox sharing the channel type', () => {
      const inbox = {
        id: 1,
        channel_type: 'Channel::Whatsapp',
        name: 'WA Biz',
      };
      const { connectedInbox } = mountComposable({
        brandInfo: {},
        inboxes: [inbox],
      });

      expect(
        connectedInbox({ inbox: { channel_type: 'Channel::Whatsapp' } })
      ).toBe(inbox);
    });

    it('matches email inboxes on provider', () => {
      const gmail = {
        id: 1,
        channel_type: 'Channel::Email',
        provider: 'google',
      };
      const outlook = {
        id: 2,
        channel_type: 'Channel::Email',
        provider: 'microsoft',
      };
      const { connectedInbox } = mountComposable({
        brandInfo: {},
        inboxes: [outlook, gmail],
      });

      expect(
        connectedInbox({
          inbox: { channel_type: 'Channel::Email', provider: 'google' },
        })
      ).toBe(gmail);
    });

    it('returns undefined when nothing matches', () => {
      const { connectedInbox } = mountComposable({
        brandInfo: {},
        inboxes: [],
      });

      expect(
        connectedInbox({ inbox: { channel_type: 'Channel::Telegram' } })
      ).toBeUndefined();
    });
  });
});
