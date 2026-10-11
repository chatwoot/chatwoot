import { defineComponent, ref } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import { createStore } from 'vuex';
import ImageBubble from '../Image.vue';
import { provideMessageContext } from '../../provider.js';

const createWrapper = ({ extension = 'png', loaded = true } = {}) => {
  const fetchAllAttachments = vi.fn();
  const attachment = {
    dataUrl: 'https://example.com/original-image.png',
    thumbUrl: 'https://example.com/image-thumbnail.png',
    extension,
    fileType: 'image',
    width: 1024,
    height: 1024,
  };

  const store = createStore({
    modules: {
      conversations: {
        state: () => ({
          attachments: loaded ? { 1: [] } : {},
        }),
      },
    },
    getters: {
      getSelectedChatAttachments: () => [],
    },
    actions: {
      fetchAllAttachments,
    },
  });

  const TestHost = defineComponent({
    components: { ImageBubble },
    setup() {
      provideMessageContext({
        attachments: ref([attachment]),
        conversationId: ref(1),
      });
    },
    template: '<ImageBubble />',
  });

  const i18n = createI18n({ legacy: false, locale: 'en' });
  const wrapper = mount(TestHost, {
    global: {
      plugins: [i18n, store],
      stubs: {
        BaseBubble: {
          emits: ['click'],
          template:
            '<button class="base-bubble" @click="$emit(\'click\')"><slot /></button>',
        },
        Button: true,
        Icon: true,
        GalleryView: true,
      },
    },
  });

  return { wrapper, fetchAllAttachments };
};

describe('Image bubble', () => {
  beforeEach(() => {
    vi.stubGlobal(
      'Image',
      class {
        set src(value) {
          this.url = value;
          this.onload();
        }
      }
    );
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('uses the thumbnail for inline image rendering', async () => {
    const { wrapper } = createWrapper();
    await flushPromises();

    expect(wrapper.find('img').attributes('src')).toBe(
      'https://example.com/image-thumbnail.png'
    );
  });

  it('uses the original image for animated GIFs', async () => {
    const { wrapper } = createWrapper({ extension: 'GIF' });
    await flushPromises();

    expect(wrapper.find('img').attributes('src')).toBe(
      'https://example.com/original-image.png'
    );
  });

  it('loads conversation attachments only when the gallery needs them', async () => {
    const { wrapper, fetchAllAttachments } = createWrapper({ loaded: false });
    await flushPromises();

    await wrapper.find('.base-bubble').trigger('click');

    expect(fetchAllAttachments).toHaveBeenCalledOnce();
    expect(fetchAllAttachments.mock.calls[0][1]).toBe(1);
  });
});
