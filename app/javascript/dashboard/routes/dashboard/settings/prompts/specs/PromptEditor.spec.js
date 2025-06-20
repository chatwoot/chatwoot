import { describe, it, expect, vi } from 'vitest';
import { shallowMount } from '@vue/test-utils';
import PromptEditor from '../PromptEditor.vue';

describe('PromptEditor.vue', () => {
  let wrapper;

  const defaultProps = {
    prompt: {
      id: 1,
      prompt_key: 'greeting',
      text: 'Hello! How can I help you today?',
    },
    isUpdating: false,
    isSaved: false,
    isReadonly: false,
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
    vi.clearAllMocks();
  });

  describe('component mounting and props', () => {
    it('should render without errors', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.exists()).toBe(true);
    });

    it('should initialize with prompt data', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.localPrompt).toEqual(defaultProps.prompt);
    });

    it('should identify new prompts correctly', () => {
      const newPromptProps = {
        ...defaultProps,
        prompt: {
          prompt_key: 'new_prompt',
          text: 'New prompt text',
        },
      };

      wrapper = shallowMount(PromptEditor, {
        props: newPromptProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.isNewPrompt).toBe(true);
    });

    it('should identify existing prompts correctly', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.isNewPrompt).toBe(false);
    });
  });

  describe('component state management', () => {
    it('should update localPrompt when promptText changes', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      const newText = 'Updated greeting message';
      wrapper.vm.promptText = newText;

      expect(wrapper.vm.localPrompt.text).toBe(newText);
    });

    it('should update localPrompt when promptKey changes', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      const newKey = 'greeting_updated';
      wrapper.vm.promptKey = newKey;

      expect(wrapper.vm.localPrompt.prompt_key).toBe(newKey);
    });
  });

  describe('event emission', () => {
    it('should emit savePrompt when onClickUpdate is called', async () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      wrapper.vm.localPrompt = {
        ...defaultProps.prompt,
        text: 'Updated text',
      };

      await wrapper.vm.onClickUpdate();

      expect(wrapper.emitted('savePrompt')).toBeTruthy();
      expect(wrapper.emitted('savePrompt')[0][0]).toEqual({
        ...defaultProps.prompt,
        text: 'Updated text',
      });
    });

    it('should emit goBack when onClickGoBack is called', async () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      await wrapper.vm.onClickGoBack();

      expect(wrapper.emitted('goBack')).toBeTruthy();
    });
  });

  describe('visual states', () => {
    it('should show saving state when isUpdating is true', () => {
      wrapper = shallowMount(PromptEditor, {
        props: {
          ...defaultProps,
          isUpdating: true,
        },
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.text()).toContain('Saving...');
    });

    it('should show saved state when isSaved is true', () => {
      wrapper = shallowMount(PromptEditor, {
        props: {
          ...defaultProps,
          isSaved: true,
        },
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.text()).toContain('Saved');
    });

    it('should not show update button when isReadonly is true', () => {
      wrapper = shallowMount(PromptEditor, {
        props: {
          ...defaultProps,
          isReadonly: true,
        },
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      // The update button should not be rendered
      expect(wrapper.text()).not.toContain('PROMPTS_PAGE.EDITOR.UPDATE_BUTTON_TEXT');
    });
  });

  describe('computed properties', () => {
    it('should return correct promptKey', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.promptKey).toBe(defaultProps.prompt.prompt_key);
    });

    it('should return correct promptText', () => {
      wrapper = shallowMount(PromptEditor, {
        props: defaultProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.promptText).toBe(defaultProps.prompt.text);
    });

    it('should handle empty prompt properties', () => {
      const emptyPromptProps = {
        ...defaultProps,
        prompt: {},
      };

      wrapper = shallowMount(PromptEditor, {
        props: emptyPromptProps,
        global: {
          mocks: {
            $t: vi.fn((key) => key),
          },
          stubs: {
            FullEditor: true,
            NextButton: true,
          },
        },
      });

      expect(wrapper.vm.promptKey).toBe('');
      expect(wrapper.vm.promptText).toBe('');
    });
  });
}); 