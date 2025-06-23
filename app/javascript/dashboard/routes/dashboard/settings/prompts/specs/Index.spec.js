import { describe, it, expect, vi, beforeEach } from 'vitest';
import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import Index from '../Index.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

// Mock the router
const mockRouter = {
  push: vi.fn(),
};

// Mock the $t function for internationalization
const mockT = vi.fn((key) => key);

describe('Index.vue', () => {
  let wrapper;
  let store;
  let actions;
  let getters;

  beforeEach(() => {
    actions = {
      'prompts/get': vi.fn(),
    };

    getters = {
      'prompts/getPrompts': vi.fn(),
      'prompts/getUIFlags': vi.fn(),
    };

    store = createStore({
      actions,
      getters,
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
    vi.clearAllMocks();
  });

  describe('component mounting', () => {
    it('should dispatch prompts/get action on mounted', () => {
      getters['prompts/getPrompts'].mockReturnValue([]);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      expect(actions['prompts/get']).toHaveBeenCalledTimes(1);
    });
  });

  describe('prompt rendering', () => {
    it('should render list of prompts correctly when prompts are available', () => {
      const mockPrompts = [
        {
          id: 1,
          prompt_key: 'greeting',
          text: 'Hello! How can I help you today?',
        },
        {
          id: 2,
          prompt_key: 'closing',
          text: 'Thank you for contacting us. Have a great day!',
        },
      ];

      getters['prompts/getPrompts'].mockReturnValue(mockPrompts);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      // Check that prompts are rendered
      const promptCards = wrapper.findAll('[data-testid="prompt-card"]');
      expect(promptCards).toHaveLength(2);

      // Check that prompt keys are displayed
      expect(wrapper.text()).toContain('greeting');
      expect(wrapper.text()).toContain('closing');

      // Check that prompt texts are displayed
      expect(wrapper.text()).toContain('Hello! How can I help you today?');
      expect(wrapper.text()).toContain('Thank you for contacting us. Have a great day!');
    });

    it('should handle prompts with long text correctly', () => {
      const mockPrompts = [
        {
          id: 1,
          prompt_key: 'long_prompt',
          text: 'This is a very long prompt text that should be truncated in the UI but still be accessible to the user when they click on the prompt card for editing. It contains multiple sentences and should test the line-clamp functionality.',
        },
      ];

      getters['prompts/getPrompts'].mockReturnValue(mockPrompts);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.text()).toContain('long_prompt');
      expect(wrapper.text()).toContain('This is a very long prompt text');
    });
  });

  describe('empty state', () => {
    it('should display empty state message when no prompts are available', () => {
      getters['prompts/getPrompts'].mockReturnValue([]);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      expect(mockT).toHaveBeenCalledWith('PROMPTS_PAGE.EMPTY_STATE');
      expect(wrapper.find('[data-testid="prompt-card"]').exists()).toBe(false);
    });

    it('should not display empty state when prompts are being fetched', () => {
      getters['prompts/getPrompts'].mockReturnValue([]);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: true });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      // Should show loading state instead of empty state
      expect(mockT).toHaveBeenCalledWith('PROMPTS_PAGE.LOADING');
      expect(mockT).not.toHaveBeenCalledWith('PROMPTS_PAGE.EMPTY_STATE');
    });
  });

  describe('navigation', () => {
    it('should navigate to edit prompt when prompt card is clicked', async () => {
      const mockPrompts = [
        {
          id: 1,
          prompt_key: 'greeting',
          text: 'Hello there!',
        },
      ];

      getters['prompts/getPrompts'].mockReturnValue(mockPrompts);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      const promptCard = wrapper.find('[data-testid="prompt-card"]');
      await promptCard.trigger('click');

      expect(mockRouter.push).toHaveBeenCalledWith({
        name: 'prompts_edit',
        params: { id: 1 },
      });
    });

    it('should navigate to edit prompt when edit button is clicked', async () => {
      const mockPrompts = [
        {
          id: 2,
          prompt_key: 'closing',
          text: 'Thank you!',
        },
      ];

      getters['prompts/getPrompts'].mockReturnValue(mockPrompts);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: false });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      const editButton = wrapper.find('[data-testid="edit-button"]');
      await editButton.trigger('click');

      expect(mockRouter.push).toHaveBeenCalledWith({
        name: 'prompts_edit',
        params: { id: 2 },
      });
    });
  });

  describe('loading state', () => {
    it('should display loading message when isFetching is true', () => {
      getters['prompts/getPrompts'].mockReturnValue([]);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: true });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      expect(mockT).toHaveBeenCalledWith('PROMPTS_PAGE.LOADING');
    });

    it('should hide prompt list when loading', () => {
      const mockPrompts = [
        { id: 1, prompt_key: 'greeting', text: 'Hello!' },
      ];

      getters['prompts/getPrompts'].mockReturnValue(mockPrompts);
      getters['prompts/getUIFlags'].mockReturnValue({ isFetching: true });

      wrapper = shallowMount(Index, {
        global: {
          plugins: [store],
          mocks: {
            $router: mockRouter,
            $t: mockT,
          },
          stubs: {
            BaseSettingsHeader: true,
            NextButton: true,
          },
        },
      });

      // Should not render prompt cards when loading
      expect(wrapper.find('[data-testid="prompt-card"]').exists()).toBe(false);
      expect(mockT).toHaveBeenCalledWith('PROMPTS_PAGE.LOADING');
    });
  });
}); 