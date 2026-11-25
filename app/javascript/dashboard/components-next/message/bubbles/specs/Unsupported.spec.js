import { defineComponent, ref, computed, nextTick } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import Unsupported from '../Unsupported.vue';
import MessageApi from 'dashboard/api/inbox/message';
import { provideMessageContext } from '../../provider.js';

vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: () => ({
    isAFacebookInbox: computed(() => false),
    isAnInstagramChannel: computed(() => false),
    isATiktokChannel: computed(() => false),
    isAWhatsAppCloudChannel: computed(() => false),
  }),
}));

vi.mock('dashboard/api/inbox/message', () => ({
  default: { fetchMedia: vi.fn(() => Promise.resolve()) },
}));
vi.mock('dashboard/composables', () => ({ useAlert: vi.fn() }));

const mountUnsupported = (contentAttributes, content = '') => {
  const TestHost = defineComponent({
    components: { Unsupported },
    setup() {
      provideMessageContext({
        id: ref(42),
        conversationId: ref(7),
        content: ref(content),
        inboxId: ref(1),
        contentAttributes: ref(contentAttributes),
      });
    },
    template: '<Unsupported />',
  });

  const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages: {
      en: {
        CONVERSATION: {
          UNSUPPORTED_MESSAGE: 'This message is not supported.',
          MASKED_MESSAGE_WHATSAPP:
            'WhatsApp does not deliver verification codes to linked devices.',
          VIEW_ONCE_MESSAGE_WHATSAPP:
            'WhatsApp does not deliver view-once messages to linked devices.',
          HISTORY_MEDIA: {
            PENDING: 'Not downloaded yet.',
            DOWNLOAD: 'Download file',
            UNAVAILABLE: 'No longer available.',
          },
        },
      },
    },
  });

  return mount(TestHost, {
    global: {
      plugins: [i18n],
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
        NextButton: {
          props: ['label'],
          emits: ['click'],
          template: '<button @click="$emit(\'click\')">{{ label }}</button>',
        },
      },
    },
  });
};

describe('Unsupported', () => {
  it('explains the masking when WhatsApp withheld the content', () => {
    const wrapper = mountUnsupported({ isUnsupported: true, isMasked: true });

    expect(wrapper.text()).toBe(
      'WhatsApp does not deliver verification codes to linked devices.'
    );
  });

  it('names a view-once message instead of blaming an unknown type', () => {
    const wrapper = mountUnsupported({ isUnsupported: true, isViewOnce: true });

    expect(wrapper.text()).toBe(
      'WhatsApp does not deliver view-once messages to linked devices.'
    );
  });

  it('falls back to the channel copy when the type is simply unknown', () => {
    const wrapper = mountUnsupported({ isUnsupported: true });

    expect(wrapper.text()).toBe('This message is not supported.');
  });

  // A history file waiting for its bytes is the one case the agent can act on, so the
  // bubble asks for that message, in that conversation.
  it('offers to download a history file that is still missing', async () => {
    const wrapper = mountUnsupported({
      isUnsupported: true,
      historyMedia: true,
      pendingMedia: { kind: 'image' },
    });

    expect(wrapper.text()).toContain('Not downloaded yet.');
    await wrapper.find('button').trigger('click');

    expect(MessageApi.fetchMedia).toHaveBeenCalledWith(7, 42);
  });

  // The download runs in the background and can fail for good while the provider is down;
  // the file then stays pending, and the button is the only way left to ask again.
  it('offers the button again a while after a request was accepted', async () => {
    vi.useFakeTimers();
    try {
      const wrapper = mountUnsupported({
        isUnsupported: true,
        historyMedia: true,
        pendingMedia: { kind: 'image' },
      });

      await wrapper.find('button').trigger('click');
      await flushPromises();
      expect(wrapper.find('button').attributes('disabled')).toBeDefined();

      vi.advanceTimersByTime(2 * 60 * 1000);
      await nextTick();
      expect(wrapper.find('button').attributes('disabled')).toBeUndefined();
    } finally {
      vi.useRealTimers();
    }
  });

  it('says a history file the provider gave up on is gone, with no button', () => {
    const wrapper = mountUnsupported({
      isUnsupported: true,
      pendingMedia: { kind: 'image' },
    });

    expect(wrapper.text()).toBe('No longer available.');
    expect(wrapper.find('button').exists()).toBe(false);
  });

  // A file that is not coming back must not take its caption with it.
  it('keeps the caption of a history file, pending or gone', () => {
    const pending = mountUnsupported(
      {
        isUnsupported: true,
        historyMedia: true,
        pendingMedia: { kind: 'image' },
      },
      'orçamento de junho'
    );
    const gone = mountUnsupported(
      { isUnsupported: true, pendingMedia: { kind: 'image' } },
      'orçamento de junho'
    );

    expect(pending.text()).toContain('orçamento de junho');
    expect(gone.text()).toContain('orçamento de junho');
    expect(gone.text()).toContain('No longer available.');
  });
});
