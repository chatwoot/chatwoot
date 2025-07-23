import { mount } from '@vue/test-utils';
import { vi } from 'vitest';
import AIAssistanceModal from '../AIAssistanceModal.vue';
import AILoader from '../AILoader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

// Mock the composables
const mockUseMessageFormatter = {
  formatMessage: vi.fn(msg => msg),
};

const mockUseAI = {
  draftMessage: 'Original draft message',
  processEvent: vi.fn(),
  recordAnalytics: vi.fn(),
};

vi.mock('shared/composables/useMessageFormatter', () => ({
  useMessageFormatter: () => mockUseMessageFormatter,
}));

vi.mock('dashboard/composables/useAI', () => ({
  useAI: () => mockUseAI,
}));

// Mock the $t function for translations
const $t = vi.fn(key => {
  const translations = {
    'INTEGRATION_SETTINGS.OPEN_AI.WITH_AI': 'AI Assistance - {option}',
    'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.REPHRASE': 'Rephrase',
    'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.FIX_SPELLING_GRAMMAR':
      'Fix Spelling & Grammar',
    'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.EXPAND': 'Expand',
    'INTEGRATION_SETTINGS.OPEN_AI.OPTIONS.SHORTEN': 'Shorten',
    'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.DRAFT_TITLE': 'Draft',
    'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.GENERATED_TITLE':
      'Generated Content',
    'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.CANCEL': 'Cancel',
    'INTEGRATION_SETTINGS.OPEN_AI.ASSISTANCE_MODAL.BUTTONS.APPLY': 'Apply',
  };
  return translations[key] || key;
});

const globalMocks = {
  $t,
};

describe('AIAssistanceModal.vue', () => {
  let wrapper;

  const defaultProps = {
    aiOption: 'rephrase',
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockUseAI.processEvent.mockResolvedValue('Generated AI content');
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
  });

  const createWrapper = (props = {}, options = {}) => {
    return mount(AIAssistanceModal, {
      props: { ...defaultProps, ...props },
      global: {
        mocks: globalMocks,
        stubs: {
          'woot-modal-header': {
            template: '<div class="modal-header">{{ headerTitle }}</div>',
            props: ['headerTitle'],
          },
        },
      },
      ...options,
    });
  };

  describe('rendering', () => {
    it('renders the modal with correct structure', () => {
      wrapper = createWrapper();

      expect(wrapper.find('.flex.flex-col').exists()).toBe(true);
      expect(wrapper.find('form.modal-content').exists()).toBe(true);
      expect(wrapper.findComponent(AILoader).exists()).toBe(true);
      expect(wrapper.findAllComponents(NextButton)).toHaveLength(2);
    });

    it('displays the correct header title based on aiOption prop', async () => {
      wrapper = createWrapper({ aiOption: 'rephrase' });

      // Wait for the component to be fully rendered
      await wrapper.vm.$nextTick();

      const headerTitle = wrapper.vm.headerTitle;
      expect(headerTitle).toContain('Rephrase');
    });

    it('displays draft message when draftMessage is available', () => {
      wrapper = createWrapper();

      expect(wrapper.find('h4').text()).toContain('Draft');
      expect(wrapper.text()).toContain('Original draft message');
    });

    it('shows AILoader when content is generating', () => {
      wrapper = createWrapper();

      expect(wrapper.findComponent(AILoader).exists()).toBe(true);
    });

    it('shows generated content when generation is complete', async () => {
      wrapper = createWrapper();

      // Simulate content generation completion
      await wrapper.setData({
        isGenerating: false,
        generatedContent: 'AI generated text',
      });

      expect(wrapper.findComponent(AILoader).exists()).toBe(false);
      expect(wrapper.text()).toContain('AI generated text');
    });

    it('renders cancel and apply buttons', () => {
      wrapper = createWrapper();

      const buttons = wrapper.findAllComponents(NextButton);
      expect(buttons).toHaveLength(2);

      // Check button labels via props
      expect(buttons[0].props('label')).toBe('Cancel');
      expect(buttons[1].props('label')).toBe('Apply');
    });

    it('disables apply button when no generated content', async () => {
      wrapper = createWrapper();
      await wrapper.setData({ generatedContent: '' });

      const applyButton = wrapper.findAllComponents(NextButton)[1];
      expect(applyButton.props('disabled')).toBe(true);
    });

    it('enables apply button when generated content is available', async () => {
      wrapper = createWrapper();
      await wrapper.setData({ generatedContent: 'Some content' });

      const applyButton = wrapper.findAllComponents(NextButton)[1];
      expect(applyButton.props('disabled')).toBe(false);
    });
  });

  describe('computed properties', () => {
    it('computes correct header title for different AI options', () => {
      const testCases = [
        { option: 'rephrase', expected: 'AI Assistance - Rephrase' },
        {
          option: 'fix_spelling_grammar',
          expected: 'AI Assistance - Fix Spelling & Grammar',
        },
        { option: 'expand', expected: 'AI Assistance - Expand' },
        { option: 'shorten', expected: 'AI Assistance - Shorten' },
      ];

      testCases.forEach(({ option, expected }) => {
        wrapper = createWrapper({ aiOption: option });
        expect(wrapper.vm.headerTitle).toContain(expected.split(' - ')[1]);
      });
    });

    it('returns empty string for invalid aiOption', () => {
      wrapper = createWrapper({ aiOption: null });
      expect(wrapper.vm.headerTitle).toBe('');
    });
  });

  describe('lifecycle methods', () => {
    it('calls generateAIContent on mount', () => {
      const generateAIContentSpy = vi.spyOn(
        AIAssistanceModal.methods,
        'generateAIContent'
      );
      wrapper = createWrapper();

      expect(generateAIContentSpy).toHaveBeenCalledWith('rephrase');
    });
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    describe('onClose', () => {
      it('emits close event when onClose is called', () => {
        wrapper.vm.onClose();

        expect(wrapper.emitted('close')).toBeTruthy();
        expect(wrapper.emitted('close')).toHaveLength(1);
      });
    });

    describe('generateAIContent', () => {
      it('sets isGenerating to true during content generation', async () => {
        const promise = Promise.resolve('Generated content');
        mockUseAI.processEvent.mockReturnValue(promise);

        wrapper.vm.generateAIContent('rephrase');

        expect(wrapper.vm.isGenerating).toBe(true);

        await promise;
        expect(wrapper.vm.isGenerating).toBe(false);
      });

      it('calls processEvent with correct type', async () => {
        await wrapper.vm.generateAIContent('expand');

        expect(mockUseAI.processEvent).toHaveBeenCalledWith('expand');
      });

      it('updates generatedContent with result', async () => {
        mockUseAI.processEvent.mockResolvedValue('New AI content');

        await wrapper.vm.generateAIContent('shorten');

        expect(wrapper.vm.generatedContent).toBe('New AI content');
      });

      it('uses default type "rephrase" when no type provided', async () => {
        await wrapper.vm.generateAIContent();

        expect(mockUseAI.processEvent).toHaveBeenCalledWith('rephrase');
      });

      it('handles errors gracefully', async () => {
        const consoleErrorSpy = vi
          .spyOn(console, 'error')
          .mockImplementation(() => {});
        mockUseAI.processEvent.mockRejectedValue(new Error('AI service error'));

        await wrapper.vm.generateAIContent('rephrase');

        expect(wrapper.vm.isGenerating).toBe(false);
        // The component should handle errors gracefully without crashing
        expect(wrapper.vm.generatedContent).toBe('');

        consoleErrorSpy.mockRestore();
      });
    });

    describe('applyText', () => {
      beforeEach(async () => {
        await wrapper.setData({ generatedContent: 'Test content' });
      });

      it('records analytics with correct option', () => {
        wrapper.vm.applyText();

        expect(mockUseAI.recordAnalytics).toHaveBeenCalledWith('rephrase');
      });

      it('emits applyText event with generated content', () => {
        wrapper.vm.applyText();

        expect(wrapper.emitted('applyText')).toBeTruthy();
        expect(wrapper.emitted('applyText')[0]).toEqual(['Test content']);
      });

      it('calls onClose after applying text', () => {
        const onCloseSpy = vi.spyOn(wrapper.vm, 'onClose');

        wrapper.vm.applyText();

        expect(onCloseSpy).toHaveBeenCalled();
      });

      it('emits close event after applying text', () => {
        wrapper.vm.applyText();

        expect(wrapper.emitted('close')).toBeTruthy();
      });
    });
  });

  describe('form interactions', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('prevents default form submission and calls applyText', async () => {
      const applyTextSpy = vi.spyOn(wrapper.vm, 'applyText');
      await wrapper.setData({ generatedContent: 'Content to apply' });

      const form = wrapper.find('form');
      await form.trigger('submit');

      expect(applyTextSpy).toHaveBeenCalled();
    });

    it('calls onClose when cancel button is clicked', async () => {
      const onCloseSpy = vi.spyOn(wrapper.vm, 'onClose');

      const cancelButton = wrapper.findAllComponents(NextButton)[0];
      await cancelButton.trigger('click');

      expect(onCloseSpy).toHaveBeenCalled();
    });
  });

  describe('edge cases', () => {
    it('handles empty generated content gracefully', async () => {
      wrapper = createWrapper();
      await wrapper.setData({ generatedContent: '', isGenerating: false });

      expect(wrapper.findComponent(AILoader).exists()).toBe(false);
      expect(wrapper.text()).not.toContain('undefined');
    });

    it('handles missing draftMessage gracefully', () => {
      mockUseAI.draftMessage = null;
      wrapper = createWrapper();

      expect(wrapper.find('h4').exists()).toBe(false);
    });

    it('handles different AI option formats', () => {
      const options = ['rephrase', 'fix_spelling_grammar', 'EXPAND', 'Shorten'];

      options.forEach(option => {
        wrapper = createWrapper({ aiOption: option });
        expect(wrapper.vm.headerTitle).toBeTruthy();
      });
    });
  });

  describe('accessibility', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('has proper form structure for screen readers', () => {
      const form = wrapper.find('form');
      expect(form.exists()).toBe(true);
      expect(form.attributes('class')).toContain('modal-content');
    });

    it('provides appropriate button types', () => {
      const buttons = wrapper.findAllComponents(NextButton);

      expect(buttons[0].props('type')).toBe('reset'); // Cancel button
      expect(buttons[1].props('type')).toBe('submit'); // Apply button
    });
  });
});
