import { computed, defineComponent, nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import TextBubble from '../Index.vue';
import { provideMessageContext } from '../../../provider.js';

const mockTranslations = vi.hoisted(() => ({
  hasTranslations: null,
  translationContent: null,
}));

vi.mock('dashboard/composables/useTranslations', async () => {
  const { computed: makeComputed, ref: makeRef } = await import('vue');
  mockTranslations.hasTranslations ??= makeRef(false);
  mockTranslations.translationContent ??= makeRef(null);
  return {
    useTranslations: () => ({
      hasTranslations: makeComputed(
        () => mockTranslations.hasTranslations.value
      ),
      translationContent: makeComputed(
        () => mockTranslations.translationContent.value
      ),
    }),
  };
});

const longContent = Array(35)
  .fill('This is a long customer message used to test the collapsed preview.')
  .join(' ');

const resizeObservers = [];

class TestResizeObserver {
  constructor(callback) {
    this.callback = callback;
    this.observe = vi.fn();
    this.unobserve = vi.fn();
    this.disconnect = vi.fn();
    resizeObservers.push(this);
  }
}

const mountBubble = content => {
  const messageContent = ref(content);
  const Host = defineComponent({
    components: { TextBubble },
    setup() {
      provideMessageContext({
        id: ref(1),
        content: messageContent,
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

  const wrapper = mount(Host, {
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
        TranslationToggle: {
          template:
            '<span class="translation-failure">Could not translate, sent as typed</span>',
        },
        AttachmentChips: true,
      },
    },
  });

  return { wrapper, messageContent };
};

describe('Text message bubble read-more control', () => {
  beforeEach(() => {
    resizeObservers.length = 0;
    mockTranslations.hasTranslations.value = false;
    mockTranslations.translationContent.value = null;
    vi.stubGlobal('ResizeObserver', TestResizeObserver);
    HTMLElement.prototype.animate = vi.fn(() => ({
      finished: Promise.resolve(),
      cancel: vi.fn(),
      play: vi.fn(),
    }));
    vi.spyOn(HTMLElement.prototype, 'scrollHeight', 'get').mockImplementation(
      function scrollHeight() {
        return this.textContent.length > 200 ? 320 : 48;
      }
    );
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    delete HTMLElement.prototype.animate;
  });

  it('keeps short messages expanded without a control', () => {
    const { wrapper } = mountBubble('A short message.');

    expect(wrapper.find('button').exists()).toBe(false);
    expect(wrapper.find('.read-more-content').classes()).not.toContain(
      'max-h-40'
    );
  });

  it('collapses long messages and lets the user expand them', async () => {
    const { wrapper } = mountBubble(longContent);
    await nextTick();
    await nextTick();
    const content = wrapper.find('.read-more-content');
    const button = wrapper.get('button');

    expect(content.classes()).toContain('max-h-40');
    expect(button.text()).toBe('Read more');
    expect(button.attributes('aria-expanded')).toBe('false');

    await button.trigger('click');

    expect(content.classes()).not.toContain('max-h-40');
    expect(wrapper.get('button').text()).toBe('Show less');
    expect(wrapper.get('button').attributes('aria-expanded')).toBe('true');
  });

  it('keeps translation failure warnings outside collapsed message text', async () => {
    const { wrapper } = mountBubble(longContent);
    await nextTick();
    await nextTick();

    const message = wrapper.get('.read-more-content');
    const warning = wrapper.get('.translation-failure');

    expect(message.classes()).toContain('max-h-40');
    expect(warning.text()).toBe('Could not translate, sent as typed');
    expect(warning.element.closest('.read-more-content')).toBeNull();
  });

  it('applies the collapsed height before animating to a long translation', async () => {
    const { wrapper } = mountBubble('Short original message.');
    await nextTick();
    await nextTick();

    const bubble = wrapper.get('[aria-busy]').element;
    const animationFrames = [];
    vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockImplementation(
      function offsetHeight() {
        if (this.classList.contains('read-more-content')) {
          return this.classList.contains('max-h-40') ? 160 : this.scrollHeight;
        }

        const content = this.querySelector('.read-more-content');
        return content ? content.offsetHeight : 0;
      }
    );
    vi.spyOn(bubble, 'animate').mockImplementation(frames => {
      animationFrames.push(frames);
      return {
        finished: Promise.resolve(),
        cancel: vi.fn(),
        play: vi.fn(),
      };
    });

    mockTranslations.translationContent.value = longContent;
    mockTranslations.hasTranslations.value = true;

    await vi.waitFor(() => expect(animationFrames.length).toBeGreaterThan(0));

    expect(wrapper.get('.read-more-content').classes()).toContain('max-h-40');
    expect(animationFrames[0].height).toEqual(['48px', '160px']);
  });

  it('reattaches the resize observer when rendered content is replaced', async () => {
    const { wrapper, messageContent } = mountBubble(longContent);
    await nextTick();
    await nextTick();

    const observer = resizeObservers[0];
    const originalContent = wrapper.get('.read-more-content').element;
    observer.observe.mockClear();
    messageContent.value = `${longContent} replacement`;

    await vi.waitFor(() => {
      expect(wrapper.text()).toContain('replacement');
      expect(observer.observe).toHaveBeenCalled();
    });

    const replacementContent = wrapper.get('.read-more-content').element;
    expect(replacementContent).not.toBe(originalContent);
    expect(observer.unobserve).toHaveBeenCalledWith(originalContent);
    expect(observer.observe).toHaveBeenLastCalledWith(replacementContent);
  });
});
