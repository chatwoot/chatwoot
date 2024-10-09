import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';
import VTooltip from 'v-tooltip';
import i18n from 'dashboard/i18n';
import ReplyBox from '../ReplyBox.vue';
import { vi } from 'vitest';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.use(VTooltip);

const i18nConfig = new VueI18n({ locale: 'en', messages: i18n });

describe('ReplyBox', () => {
  let state = null;
  let store = null;
  let wrapper = null;

  const mockEmitter = {
    on: vi.fn(),
    off: vi.fn(),
    emit: vi.fn(),
  };

  beforeEach(() => {
    state = {
      authenticated: true,
    };

    store = new Vuex.Store({
      state,
      getters: {
        'contacts/getContact': () =>
          vi.fn().mockReturnValue({ email: 'contact@example.com' }),
        'inboxes/getInbox': () =>
          vi.fn().mockReturnValue({
            id: 1,
            name: 'Inbox 1',
            email: 'support@mycompany.example.com',
          }),
        'inboxes/getWhatsAppTemplates': () => vi.fn().mockReturnValue([]),
        'inboxes/getWhatsAppTemplate': () => vi.fn().mockReturnValue({}),
        'conversations/getConversation': () => vi.fn().mockReturnValue({}),
        'accounts/isFeatureEnabledonAccount': () =>
          vi.fn().mockReturnValue(true),
        getUISettings: () =>
          vi.fn().mockReturnValue({
            is_ct_labels_open: true,
            editor_message_key: 'enter',
          }),
        getMessageSignature: vi.fn().mockReturnValue('Sample Signature'),
        'integrations/getUIFlags': vi
          .fn()
          .mockReturnValue({ isFetching: true }),
        getLastEmailInSelectedChat: vi.fn().mockReturnValue({
          content_attributes: {
            email: {
              cc: ['jill@aaa.test'],
              to: ['support@mycompany.example.com', 'jane@aaa.test'],
              from: ['john@aaa.test'],
              bcc: ['bcc1@example.com', 'bcc2@example.com'],
            },
          },
        }),
        getSelectedChat: vi.fn().mockReturnValue({
          meta: {
            sender: {
              email: 'contact@example.com',
            },
          },
        }),
      },
    });

    wrapper = mount(ReplyBox, {
      store,
      localVue,
      i18n: i18nConfig,
      mocks: {
        $store: store,
        $emitter: mockEmitter, // Inject the mocked $emitter here
      },
      data() {
        return {};
      },
    });
  });

  describe('setCCAndToEmailsFromLastChat', () => {
    it('adds emails from the last email to the cc field, excluding specific addresses, and adds the conversation contact to the cc field', () => {
      // Test scenario where "To" addresses are not excluded
      wrapper.vm.setCCAndToEmailsFromLastChat();

      expect(wrapper.vm.toEmails).toBe('john@aaa.test');
      expect(wrapper.vm.bccEmails).toBe('bcc1@example.com, bcc2@example.com');
      expect(wrapper.vm.ccEmails).toBe(
        'jill@aaa.test, jane@aaa.test, contact@example.com'
      );
    });

    it('should remove reply-to email from cc field', () => {
      wrapper.setData({
        lastEmail: {
          content_attributes: {
            email: {
              cc: ['jill@aaa.test'],
              to: [
                'support@mycompany.example.com',
                'jane@aaa.test',
                'jane2@aaa.test',
                'reply+xxx@mycompany.example.com)',
              ],
              from: ['john@aaa.test'],
              bcc: ['bcc1@example.com', 'bcc2@example.com'],
            },
          },
        },
        currentChat: {
          meta: {
            sender: {
              email: 'contact@example.com',
            },
          },
        },
      });

      wrapper.vm.setCCAndToEmailsFromLastChat();

      expect(wrapper.vm.toEmails).toBe('john@aaa.test');
      expect(wrapper.vm.bccEmails).toBe('bcc1@example.com, bcc2@example.com');
      expect(wrapper.vm.ccEmails).toBe(
        'jill@aaa.test, jane@aaa.test, jane2@aaa.test, contact@example.com'
      );
    });
  });
});
