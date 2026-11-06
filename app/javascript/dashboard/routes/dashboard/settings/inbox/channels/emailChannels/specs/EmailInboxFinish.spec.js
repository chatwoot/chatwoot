import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import EmailInboxFinish from '../EmailInboxFinish.vue';
import inboxMgmt from 'dashboard/i18n/locale/en/inboxMgmt.json';

const translate = key =>
  key.split('.').reduce((value, part) => value[part], inboxMgmt);

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: translate }) }));
vi.mock('dashboard/composables/store.js', () => ({
  useMapGetter: () => ref({ installationName: 'Acme Support' }),
}));

describe('EmailInboxFinish', () => {
  it.each([true, false])(
    'describes incoming mail without promising SMTP when SMTP is %s',
    smtpEnabled => {
      const wrapper = shallowMount(EmailInboxFinish, {
        props: {
          inbox: { imap_enabled: true, smtp_enabled: smtpEnabled },
          inboxId: 1,
        },
        global: {
          mocks: { $t: translate },
          stubs: ['router-link', 'woot-code'],
        },
      });

      expect(wrapper.find('p').text()).toBe(
        'Your email inbox is connected. Acme Support will fetch new emails from your mailbox.'
      );
    }
  );

  it.each([true, false])(
    'brands the completion message with IMAP enabled: %s',
    imapEnabled => {
      const wrapper = shallowMount(EmailInboxFinish, {
        props: { inbox: { imap_enabled: imapEnabled }, inboxId: 1 },
        global: {
          mocks: { $t: translate },
          stubs: ['router-link', 'woot-code'],
        },
      });

      expect(wrapper.text()).toContain('Acme Support');
      expect(wrapper.text()).not.toContain('Chatwoot');
    }
  );
});
