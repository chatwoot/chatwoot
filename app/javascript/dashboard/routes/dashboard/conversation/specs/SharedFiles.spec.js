import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import { createStore } from 'vuex';
import SharedFiles from '../SharedFiles.vue';

const createWrapper = ({ loaded = false } = {}) => {
  const fetchAllAttachments = vi.fn();
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
  const i18n = createI18n({ legacy: false, locale: 'en' });

  const wrapper = mount(SharedFiles, {
    props: { conversationId: 1 },
    global: {
      plugins: [i18n, store],
      stubs: {
        GalleryView: true,
        Media: true,
        Files: true,
        Spinner: true,
      },
    },
  });

  return { wrapper, fetchAllAttachments };
};

describe('SharedFiles', () => {
  it('fetches attachments when opened before they are loaded', () => {
    const { fetchAllAttachments } = createWrapper();

    expect(fetchAllAttachments).toHaveBeenCalledOnce();
    expect(fetchAllAttachments.mock.calls[0][1]).toBe(1);
  });

  it('reuses attachments already loaded for the conversation', () => {
    const { fetchAllAttachments } = createWrapper({ loaded: true });

    expect(fetchAllAttachments).not.toHaveBeenCalled();
  });
});
