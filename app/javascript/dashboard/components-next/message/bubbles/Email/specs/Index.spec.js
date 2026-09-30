import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import EmailBubble from '../Index.vue';
import { provideMessageContext } from '../../../provider.js';
import { MESSAGE_TYPES } from '../../../constants';

vi.mock('dashboard/composables/useTranslations', async () => {
  const { ref: makeRef } = await import('vue');
  return {
    useTranslations: () => ({
      hasTranslations: makeRef(false),
      translationContent: makeRef(''),
    }),
  };
});

const html = '<p>Latest reply</p><div class="gmail_quote">Older reply</div>';

const mountBubble = contentAttributes => {
  const Host = defineComponent({
    components: { EmailBubble },
    setup() {
      provideMessageContext({
        content: ref('Latest reply'),
        contentAttributes: ref({
          email: {
            htmlContent: { full: html },
            textContent: { full: 'Latest reply' },
          },
          ...contentAttributes,
        }),
        attachments: ref([]),
        messageType: ref(MESSAGE_TYPES.OUTGOING),
      });
    },
    template: '<EmailBubble />',
  });

  return mount(Host, {
    global: {
      mocks: { $store: { getters: { getSelectedChatAttachments: [] } } },
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
        EmailMeta: true,
        AttachmentChips: true,
        TranslationToggle: true,
        Icon: true,
      },
    },
  });
};

describe('Email bubble', () => {
  it('collapses quoted history behind the toggle for regular emails', () => {
    const wrapper = mountBubble({});
    const letter = wrapper.find('.letter-render');

    expect(letter.text()).toContain('Latest reply');
    expect(letter.text()).not.toContain('Older reply');
    expect(wrapper.text()).toContain('CHAT_LIST.SHOW_QUOTED_TEXT');
  });

  it('shows the full body for a forwarded email', () => {
    const wrapper = mountBubble({ forwardedMessageId: 501 });
    const letter = wrapper.find('.letter-render');

    expect(letter.text()).toContain('Latest reply');
    expect(letter.text()).toContain('Older reply');
    expect(wrapper.text()).not.toContain('CHAT_LIST.SHOW_QUOTED_TEXT');
  });
});
