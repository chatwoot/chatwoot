import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { vi } from 'vitest';
import StickerPicker from './StickerPicker.vue';

// Mock the composables
vi.mock('dashboard/composables', () => ({
  useAlert: () => ({
    showAlert: vi.fn(),
  }),
}));

// Mock the utils
vi.mock('@chatwoot/utils', () => ({
  debounce: vi.fn(fn => fn),
}));

const createWrapper = (props = {}) => {
  const store = createStore({
    modules: {
      auth: {
        namespaced: true,
        getters: {
          getCurrentUser: () => ({ id: 1, name: 'Test User' }),
        },
      },
      accounts: {
        namespaced: true,
        getters: {
          getCurrentAccount: () => ({ id: 1, name: 'Test Account' }),
        },
      },
    },
  });

  return mount(StickerPicker, {
    props: {
      conversationId: 1,
      isVisible: true,
      ...props,
    },
    global: {
      plugins: [store],
      mocks: {
        $t: key => key,
        $http: {
          get: vi.fn(),
          post: vi.fn(),
        },
      },
    },
  });
};

describe('StickerPicker', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Component Rendering', () => {
    it('renders the modal when visible', () => {
      const wrapper = createWrapper({ isVisible: true });
      expect(wrapper.find('.sticker-picker-modal').exists()).toBe(true);
    });

    it('does not render when not visible', () => {
      const wrapper = createWrapper({ isVisible: false });
      expect(wrapper.find('.sticker-picker-modal').exists()).toBe(false);
    });

    it('renders all default tabs', () => {
      const wrapper = createWrapper();
      const tabs = wrapper.findAll('button');
      expect(tabs).toHaveLength(3); // Trending, Search, Recent
      expect(tabs[0].text()).toBe('CONVERSATION.STICKER_PICKER.TABS.TRENDING');
      expect(tabs[1].text()).toBe('CONVERSATION.STICKER_PICKER.TABS.SEARCH');
      expect(tabs[2].text()).toBe('CONVERSATION.STICKER_PICKER.TABS.RECENT');
    });

    it('shows search input only for search tab', async () => {
      const wrapper = createWrapper();

      // Initially on trending tab - no search input
      expect(wrapper.find('input').exists()).toBe(false);

      // Switch to search tab
      await wrapper.vm.switchTab('search');
      await wrapper.vm.$nextTick();

      expect(wrapper.find('input').exists()).toBe(true);
      expect(wrapper.find('input').attributes('placeholder')).toBe(
        'CONVERSATION.STICKER_PICKER.SEARCH_PLACEHOLDER'
      );
    });
  });

  describe('Tab Switching', () => {
    it('switches tabs correctly', async () => {
      const wrapper = createWrapper();

      expect(wrapper.vm.activeTab).toBe('trending');

      await wrapper.vm.switchTab('search');
      expect(wrapper.vm.activeTab).toBe('search');

      await wrapper.vm.switchTab('recent');
      expect(wrapper.vm.activeTab).toBe('recent');
    });

    it('clears search term when switching tabs', async () => {
      const wrapper = createWrapper();

      wrapper.vm.searchTerm = 'test search';
      await wrapper.vm.switchTab('recent');

      expect(wrapper.vm.searchTerm).toBe('');
    });

    it('clears error when switching tabs', async () => {
      const wrapper = createWrapper();

      wrapper.vm.error = 'Test error';
      await wrapper.vm.switchTab('recent');

      expect(wrapper.vm.error).toBe(null);
    });
  });

  describe('Loading States', () => {
    it('shows loading state', async () => {
      const wrapper = createWrapper();

      wrapper.vm.isLoading = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find('.animate-spin').exists()).toBe(true);
      expect(wrapper.text()).toContain('CONVERSATION.STICKER_PICKER.LOADING');
    });

    it('shows search loading state', async () => {
      const wrapper = createWrapper();

      await wrapper.vm.switchTab('search');
      wrapper.vm.isSearching = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find('input + div .animate-spin').exists()).toBe(true);
    });
  });

  describe('Error Handling', () => {
    it('shows error state', async () => {
      const wrapper = createWrapper();

      wrapper.vm.error = 'Test error message';
      wrapper.vm.isLoading = false;
      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain('Test error message');
      const retryButton = wrapper
        .findAll('button')
        .find(btn => btn.text().includes('CONVERSATION.STICKER_PICKER.RETRY'));
      expect(retryButton).toBeTruthy();
    });

    it('retries loading on retry button click', async () => {
      const wrapper = createWrapper();
      const loadTabDataSpy = vi.spyOn(wrapper.vm, 'loadTabData');

      wrapper.vm.error = 'Test error';
      await wrapper.vm.$nextTick();

      await wrapper.find('button').trigger('click');
      expect(loadTabDataSpy).toHaveBeenCalled();
    });
  });

  describe('Empty States', () => {
    it('shows empty state when no stickers', async () => {
      const wrapper = createWrapper();

      wrapper.vm.stickers = [];
      wrapper.vm.isLoading = false;
      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain(
        'CONVERSATION.STICKER_PICKER.EMPTY_STATES.TRENDING'
      );
    });

    it('shows correct empty state message for each tab', async () => {
      const wrapper = createWrapper();
      wrapper.vm.stickers = [];
      wrapper.vm.isLoading = false;

      // Trending tab
      expect(wrapper.vm.emptyStateMessage).toBe(
        'CONVERSATION.STICKER_PICKER.EMPTY_STATES.TRENDING'
      );

      // Search tab
      await wrapper.vm.switchTab('search');
      expect(wrapper.vm.emptyStateMessage).toBe(
        'CONVERSATION.STICKER_PICKER.EMPTY_STATES.SEARCH_PROMPT'
      );

      wrapper.vm.searchTerm = 'test';
      expect(wrapper.vm.emptyStateMessage).toBe(
        'CONVERSATION.STICKER_PICKER.EMPTY_STATES.SEARCH_RESULTS'
      );

      // Recent tab
      await wrapper.vm.switchTab('recent');
      expect(wrapper.vm.emptyStateMessage).toBe(
        'CONVERSATION.STICKER_PICKER.EMPTY_STATES.RECENT'
      );
    });
  });

  describe('Sticker Grid', () => {
    it('renders stickers in grid', async () => {
      const wrapper = createWrapper();

      wrapper.vm.stickers = [
        {
          id: '1',
          url: 'http://example.com/sticker1.webp',
          alt: 'Sticker 1',
          provider: 'giphy',
        },
        {
          id: '2',
          url: 'http://example.com/sticker2.webp',
          alt: 'Sticker 2',
          provider: 'giphy',
        },
      ];
      wrapper.vm.isLoading = false;
      await wrapper.vm.$nextTick();

      const stickerImages = wrapper.findAll('.grid img');
      expect(stickerImages).toHaveLength(2);
      expect(stickerImages[0].attributes('src')).toBe(
        'http://example.com/sticker1.webp'
      );
      expect(stickerImages[0].attributes('alt')).toBe('Sticker 1');
    });

    it('handles sticker selection', async () => {
      const wrapper = createWrapper();
      const selectStickerSpy = vi.spyOn(wrapper.vm, 'selectSticker');

      const testSticker = {
        id: '1',
        url: 'http://example.com/sticker1.webp',
        alt: 'Sticker 1',
        provider: 'giphy',
      };
      wrapper.vm.stickers = [testSticker];
      wrapper.vm.isLoading = false;
      await wrapper.vm.$nextTick();

      await wrapper.find('.grid > div').trigger('click');
      expect(selectStickerSpy).toHaveBeenCalledWith(testSticker);
    });
  });

  describe('API Integration', () => {
    it('loads trending stickers on mount', async () => {
      const mockGet = vi.fn().mockResolvedValue({
        data: {
          stickers: [
            { id: '1', url: 'test.webp', alt: 'Test', provider: 'giphy' },
          ],
        },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(mockGet).toHaveBeenCalledWith('/api/v1/accounts/1/stickers', {
        params: { provider: 'giphy' },
      });
    });

    it('loads recent stickers', async () => {
      const mockGet = vi.fn().mockResolvedValue({
        data: { stickers: [] },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;
      wrapper.vm.activeTab = 'recent';

      await wrapper.vm.loadTabData();

      expect(mockGet).toHaveBeenCalledWith('/api/v1/accounts/1/stickers', {
        params: { provider: 'recent' },
      });
    });

    it('performs search', async () => {
      const mockGet = vi.fn().mockResolvedValue({
        data: { stickers: [] },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;
      wrapper.vm.searchTerm = 'funny cats';

      await wrapper.vm.performSearch();

      expect(mockGet).toHaveBeenCalledWith('/api/v1/accounts/1/stickers', {
        params: { provider: 'giphy', search_term: 'funny cats' },
      });
    });

    it('sends sticker successfully', async () => {
      const mockPost = vi.fn().mockResolvedValue({
        data: { success: true, message_id: 123 },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.post = mockPost;

      const sticker = {
        id: '1',
        url: 'test.webp',
        alt: 'Test',
        provider: 'giphy',
      };
      await wrapper.vm.selectSticker(sticker);

      expect(mockPost).toHaveBeenCalledWith(
        '/api/v1/accounts/1/stickers/send_sticker',
        {
          conversation_id: 1,
          sticker: sticker,
        }
      );
      expect(wrapper.emitted('sticker-selected')).toBeTruthy();
      expect(wrapper.emitted('close')).toBeTruthy();
    });

    it('handles sticker send failure', async () => {
      const mockPost = vi.fn().mockRejectedValue(new Error('Network error'));
      const mockShowAlert = vi.fn();

      const wrapper = createWrapper();
      wrapper.vm.$http.post = mockPost;
      wrapper.vm.showAlert = mockShowAlert;

      const sticker = {
        id: '1',
        url: 'test.webp',
        alt: 'Test',
        provider: 'giphy',
      };
      await wrapper.vm.selectSticker(sticker);

      expect(mockShowAlert).toHaveBeenCalledWith(
        'CONVERSATION.STICKER_PICKER.ERRORS.SEND_FAILED'
      );
      expect(wrapper.emitted('sticker-selected')).toBeFalsy();
      expect(wrapper.emitted('close')).toBeFalsy();
    });

    it('handles API error responses', async () => {
      const mockGet = vi.fn().mockResolvedValue({
        data: {
          error: 'GIPHY_API_KEY_MISSING',
          message: 'Giphy integration not configured',
          user_message: 'Giphy integration not available.',
        },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(wrapper.vm.error).toBe(
        'CONVERSATION.STICKER_PICKER.ERRORS.GIPHY_NOT_CONFIGURED'
      );
    });

    it('handles network errors', async () => {
      const networkError = new Error('Network Error');
      networkError.code = 'NETWORK_ERROR';
      const mockGet = vi.fn().mockRejectedValue(networkError);

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(wrapper.vm.error).toBe(
        'CONVERSATION.STICKER_PICKER.ERRORS.NETWORK_ERROR'
      );
    });

    it('handles rate limit errors', async () => {
      const rateLimitError = new Error('Rate Limited');
      rateLimitError.response = { status: 429 };
      const mockGet = vi.fn().mockRejectedValue(rateLimitError);

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(wrapper.vm.error).toBe(
        'CONVERSATION.STICKER_PICKER.ERRORS.RATE_LIMIT'
      );
    });

    it('handles server errors', async () => {
      const serverError = new Error('Server Error');
      serverError.response = { status: 500 };
      const mockGet = vi.fn().mockRejectedValue(serverError);

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(wrapper.vm.error).toBe(
        'CONVERSATION.STICKER_PICKER.ERRORS.SERVER_ERROR'
      );
    });

    it('handles service unavailable errors', async () => {
      const serviceError = new Error('Service Unavailable');
      serviceError.response = { status: 503 };
      const mockGet = vi.fn().mockRejectedValue(serviceError);

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadTabData();

      expect(wrapper.vm.error).toBe(
        'CONVERSATION.STICKER_PICKER.ERRORS.SERVICE_UNAVAILABLE'
      );
    });

    it('handles sticker send error responses', async () => {
      const mockPost = vi.fn().mockRejectedValue({
        response: {
          data: {
            error_code: 'WHATSAPP_RATE_LIMIT',
            user_message: 'Too many messages sent. Please wait.',
          },
        },
      });
      const mockShowAlert = vi.fn();

      const wrapper = createWrapper();
      wrapper.vm.$http.post = mockPost;
      wrapper.vm.showAlert = mockShowAlert;

      const sticker = {
        id: '1',
        url: 'test.webp',
        alt: 'Test',
        provider: 'giphy',
      };
      await wrapper.vm.selectSticker(sticker);

      expect(mockShowAlert).toHaveBeenCalledWith(
        'CONVERSATION.STICKER_PICKER.ERRORS.WHATSAPP_RATE_LIMIT'
      );
    });

    it('handles invalid channel error', async () => {
      const mockPost = vi.fn().mockRejectedValue({
        response: {
          data: {
            error_code: 'INVALID_CHANNEL_TYPE',
            user_message:
              'Stickers can only be sent in WhatsApp conversations.',
          },
        },
      });
      const mockShowAlert = vi.fn();

      const wrapper = createWrapper();
      wrapper.vm.$http.post = mockPost;
      wrapper.vm.showAlert = mockShowAlert;

      const sticker = {
        id: '1',
        url: 'test.webp',
        alt: 'Test',
        provider: 'giphy',
      };
      await wrapper.vm.selectSticker(sticker);

      expect(mockShowAlert).toHaveBeenCalledWith(
        'CONVERSATION.STICKER_PICKER.ERRORS.INVALID_CHANNEL'
      );
    });
  });

  describe('Custom Packs', () => {
    it('loads custom packs', async () => {
      const mockGet = vi.fn().mockResolvedValue({
        data: {
          stickers: [
            {
              id: '1',
              url: 'custom1.webp',
              alt: 'Custom 1',
              provider: 'custom',
              meta: { sticker_pack: 'Brand' },
            },
            {
              id: '2',
              url: 'custom2.webp',
              alt: 'Custom 2',
              provider: 'custom',
              meta: { sticker_pack: 'Emoji' },
            },
          ],
        },
      });

      const wrapper = createWrapper();
      wrapper.vm.$http.get = mockGet;

      await wrapper.vm.loadCustomPacks();

      expect(wrapper.vm.customPacks).toHaveLength(2);
      expect(wrapper.vm.customPacks[0].label).toBe('Brand');
      expect(wrapper.vm.customPacks[1].label).toBe('Emoji');
      expect(wrapper.vm.tabs).toHaveLength(5); // 3 default + 2 custom
    });

    it('handles custom pack selection', async () => {
      const wrapper = createWrapper();

      wrapper.vm.customPacks = [
        {
          key: 'pack_Brand',
          label: 'Brand',
          stickers: [
            { id: '1', url: 'brand1.webp', alt: 'Brand 1', provider: 'custom' },
          ],
        },
      ];

      await wrapper.vm.switchTab('pack_Brand');
      await wrapper.vm.loadTabData();

      expect(wrapper.vm.stickers).toHaveLength(1);
      expect(wrapper.vm.stickers[0].alt).toBe('Brand 1');
    });
  });

  describe('Modal Interaction', () => {
    it('emits close event when clicking overlay', async () => {
      const wrapper = createWrapper();

      await wrapper.find('.fixed.inset-0').trigger('click');
      expect(wrapper.emitted('close')).toBeTruthy();
    });

    it('does not close when clicking modal content', async () => {
      const wrapper = createWrapper();

      await wrapper.find('.bg-white.rounded-t-lg').trigger('click');
      expect(wrapper.emitted('close')).toBeFalsy();
    });

    it('calls closeModal method', async () => {
      const wrapper = createWrapper();
      const closeModalSpy = vi.spyOn(wrapper.vm, 'closeModal');

      wrapper.vm.closeModal();
      expect(closeModalSpy).toHaveBeenCalled();
      expect(wrapper.emitted('close')).toBeTruthy();
    });
  });

  describe('Image Error Handling', () => {
    it('handles image load errors', async () => {
      const wrapper = createWrapper();

      wrapper.vm.stickers = [
        { id: '1', url: 'broken-image.webp', alt: 'Broken', provider: 'giphy' },
      ];
      wrapper.vm.isLoading = false;
      await wrapper.vm.$nextTick();

      const img = wrapper.find('img');
      await img.trigger('error');

      expect(img.element.style.display).toBe('none');
    });
  });
});
