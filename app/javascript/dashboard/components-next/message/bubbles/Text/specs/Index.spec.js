import { computed, defineComponent, nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import TextBubble from '../Index.vue';
import { provideMessageContext } from '../../../provider.js';

vi.mock('dashboard/composables/useTranslations', async () => {
  const { computed: makeComputed } = await import('vue');
  return {
    useTranslations: () => ({
      hasTranslations: makeComputed(() => false),
      translationContent: makeComputed(() => null),
    }),
  };
});

const longContent = Array(35)
  .fill('This is a long customer message used to test the collapsed preview.')
  .join(' ');

const mountBubble = content => {
  const Host = defineComponent({
    components: { TextBubble },
    setup() {
      provideMessageContext({
        id: ref(1),
        content: ref(content),
        attachments: ref([]),
        contentAttributes: ref({}),
        messageType: ref(0),
        contactSide: ref(true),
        status: ref('read'),
        showingOriginal: ref(false),
        isCaptainMessage: computed(() => false),
        variant: computed(() => 'user'),
        orientation: computed(() => 'left'),
        inReplyTo: ref(null),
        shouldGroupWithNext: ref(false),
      });
      return {};
    },
    template: '<TextBubble />',
  });

  return mount(Host, {
    global: {
      config: {
        globalProperties: {
          $store: {
            getters: {
              getSelectedChatAttachments: [],
              getMessageTranslationState: () => ({ pending: false }),
            },
          },
        },
      },
      mocks: {
        $t: key =>
          ({
            'CONVERSATION.READ_MORE': 'Read more',
            'CONVERSATION.READ_LESS': 'Show less',
          })[key] || key,
      },
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
        FormattedContent: {
          props: ['content'],
          template: '<span>{{ content }}</span>',
        },
        TranslationToggle: true,
        AttachmentChips: true,
      },
    },
  });
};

describe('Text message bubble read-more control', () => {
  beforeEach(() => {
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(
      function scrollHeight() {
        return this.textContent.length > 200 ? 320 : 48;
      }
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('keeps short messages expanded without a control', () => {
    const wrapper = mountBubble('A short message.');

    expect(wrapper.find('button').exists()).toBe(false);
    expect(wrapper.find('.overflow-hidden').classes()).not.toContain(
      'max-h-40'
    );
  });

  it('collapses long messages and lets the user expand them', async () => {
    const wrapper = mountBubble(longContent);
    await nextTick();
    await nextTick();
    const content = wrapper.find('.overflow-hidden');
    const button = wrapper.get('button');

    expect(content.classes()).toContain('max-h-40');
    expect(button.text()).toBe('Read more');
    expect(button.attributes('aria-expanded')).toBe('false');

    await button.trigger('click');

    expect(content.classes()).not.toContain('max-h-40');
    expect(wrapper.get('button').text()).toBe('Show less');
    expect(wrapper.get('button').attributes('aria-expanded')).toBe('true');
  });
});
