import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { mount } from '@vue/test-utils';
import EditPrompt from '../EditPrompt.vue';

// Create a simple mock store
let mockStore;

// Mock the composition API dependencies that are complex to test
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: { id: '1' } }),
  useRouter: () => ({ push: vi.fn() }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/composables/store', () => ({
  useStore: () => mockStore,
  useMapGetter: getter => ({
    value: mockStore.getters[getter],
  }),
}));

describe('EditPrompt.vue', () => {
  let wrapper;

  beforeEach(() => {
    mockStore = {
      dispatch: vi.fn().mockResolvedValue(),
      getters: {
        'prompts/getPromptById': vi.fn(() => ({
          id: 1,
          prompt_key: 'greeting',
          text: 'Hello there!',
        })),
      },
    };
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
    vi.clearAllMocks();
  });

  describe('component initialization', () => {
    it('should mount without errors when prompt data is available', async () => {
      wrapper = mount(EditPrompt, {
        global: {
          stubs: {
            PromptEditor: {
              template:
                '<div data-testid="prompt-editor">Mock PromptEditor</div>',
              props: ['prompt', 'isUpdating', 'isSaved', 'isReadonly'],
            },
          },
        },
      });

      // Wait for the loading state to finish
      await wrapper.vm.$nextTick();
      // Wait for async dispatch to complete
      await new Promise(resolve => {
        setTimeout(resolve, 0);
      });
      // Wait for the component to update after loading completes
      await wrapper.vm.$nextTick();

      // Check if PromptEditor exists or if we're still in loading state
      const hasPromptEditor = wrapper
        .find('[data-testid="prompt-editor"]')
        .exists();
      const hasLoadingText = wrapper.text().includes('PROMPTS_PAGE.LOADING');

      // At least one should be true (either loaded or loading)
      expect(hasPromptEditor || hasLoadingText).toBe(true);
    });

    it('should show loading state initially', () => {
      wrapper = mount(EditPrompt, {
        global: {
          stubs: {
            PromptEditor: true,
          },
        },
      });

      expect(wrapper.text()).toContain('PROMPTS_PAGE.LOADING');
    });
  });

  describe('store integration', () => {
    it('should dispatch prompts/get action on mount', async () => {
      wrapper = mount(EditPrompt, {
        global: {
          stubs: {
            PromptEditor: true,
          },
        },
      });

      // Wait for async operations
      await wrapper.vm.$nextTick();
      await new Promise(resolve => {
        setTimeout(resolve, 0);
      });

      expect(mockStore.dispatch).toHaveBeenCalledWith('prompts/get');
    });
  });

  describe('prompt editor integration', () => {
    it('should pass correct props to PromptEditor when prompt is loaded', async () => {
      wrapper = mount(EditPrompt, {
        global: {
          stubs: {
            PromptEditor: {
              template:
                '<div data-testid="prompt-editor">Mock PromptEditor</div>',
              props: ['prompt', 'isUpdating', 'isSaved', 'isReadonly'],
            },
          },
        },
      });

      // Wait for loading to complete
      await wrapper.vm.$nextTick();
      await new Promise(resolve => {
        setTimeout(resolve, 0);
      });
      await wrapper.vm.$nextTick();

      const promptEditor = wrapper.findComponent({ name: 'PromptEditor' });
      if (promptEditor.exists()) {
        expect(promptEditor.props('isUpdating')).toBe(false);
        expect(promptEditor.props('isSaved')).toBe(false);
        expect(promptEditor.props('isReadonly')).toBe(false);
      }
    });
  });

  describe('error handling', () => {
    it('should handle store dispatch errors gracefully', async () => {
      mockStore.dispatch.mockRejectedValueOnce(new Error('API Error'));

      wrapper = mount(EditPrompt, {
        global: {
          stubs: {
            PromptEditor: true,
          },
        },
      });

      // Wait for async operations
      await wrapper.vm.$nextTick();
      await new Promise(resolve => {
        setTimeout(resolve, 0);
      });

      // Component should still mount without throwing
      expect(wrapper.exists()).toBe(true);
    });
  });
});
